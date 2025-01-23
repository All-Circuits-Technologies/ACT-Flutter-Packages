// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_ble_manager_ui/src/blocs/connect_to_device/ble_connect_to_device_event.dart';
import 'package:act_ble_manager_ui/src/blocs/connect_to_device/ble_connect_to_device_state.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mutex/mutex.dart';

/// This bloc is useful for views which manage the connection to detected device
///
/// In your view, you may emit the events:
/// - [ChooseDeviceToConnectToEvent] to fire the connection to a device.
/// - [DisconnectDeviceEvent] to disconnect the currently connected device.
///
/// This bloc doesn't manage the redirection to a page in case of a device disconnection, if you
/// want to do that, see the mixin: [MixinRequiredBleDeviceConnection]
class BleConnectToDeviceBloc extends Bloc<BleConnectToDeviceEvent, BleConnectToDeviceState> {
  /// If not null, this callback is called in the Ble manager connection process. It's called just
  /// after the connection and before the service discovery
  final VoidCallback? onLowLevelConnectionCallback;

  /// This mutex is used to prevent incoherent multiple parallel calls
  final Mutex _connectionMutex;

  /// This is the stream subscription linked to the device connection state
  StreamSubscription? _connectionSub;

  /// This is the stream subscription linked to the device bond state
  StreamSubscription? _bondStateSub;

  /// Class constructor
  BleConnectToDeviceBloc({
    this.onLowLevelConnectionCallback,
  })  : _connectionMutex = Mutex(),
        super(const InitBleConnectToDeviceState()) {
    on<ChooseDeviceToConnectToEvent>(_onChooseDeviceToConnectToEvent);
    on<NewDeviceStateEvent>(_onNewDeviceStateEvent);
    on<DisconnectDeviceEvent>(_onDisconnectDeviceEvent);
  }

  /// Called when the [ChooseDeviceToConnectToEvent] event is emitted
  ///
  /// This method manages the connection to a device
  Future<void> _onChooseDeviceToConnectToEvent(
    ChooseDeviceToConnectToEvent event,
    Emitter<BleConnectToDeviceState> emitter,
  ) =>
      _connectionMutex.protect(() async {
        final bleManager = globalGetIt().get<BleManager>();
        var deviceToConnectTo = bleManager.bleGattService.lastConnectedDevice;
        final sameDevice =
            (deviceToConnectTo != null && event.deviceToConnectTo.id == deviceToConnectTo.id);

        if (!sameDevice) {
          deviceToConnectTo = BleDevice(event.deviceToConnectTo);
        }

        await _focusOnNewDevice(deviceToConnectTo);

        emitter(BleNewDeviceState(
          previousState: state,
          device: deviceToConnectTo,
        ));

        if (sameDevice) {
          // Nothing more to do
          return;
        }

        emitter(LoadingConnectState(
          previousState: state,
          loading: true,
        ));

        if (!(await bleManager.bleGattService.connect(
          deviceToConnectTo,
          onLowLevelConnect: onLowLevelConnectionCallback,
        ))) {
          emitter.call(BleConnectionFailedState(previousState: state));
          return;
        }

        // If the connection succeeds, there is nothing more to do: the connected state will be
        // retrieved by the device connection state listening
        // We at least set loading to false
        emitter(LoadingConnectState(
          previousState: state,
          loading: false,
        ));
      });

  /// This method update the device states subscriptions with he new device
  /// If [newDevice] is null, we simply cancel the subscriptions
  Future<void> _focusOnNewDevice(BleDevice? newDevice) async {
    if (newDevice == state.device) {
      // Nothing to do
      return;
    }

    await _connectionSub?.cancel();
    _connectionSub = null;
    await _bondStateSub?.cancel();
    _bondStateSub = null;

    if (newDevice == null) {
      // Nothing more to do
      return;
    }

    _connectionSub = newDevice.connectionStateStream.listen(_onNewConnectionState);
    _bondStateSub = newDevice.bondStateStream.listen(_onNewBondState);
  }

  /// Called when the [DeviceConnectionState] of the [state.device] is updated
  void _onNewConnectionState(DeviceConnectionState value) {
    if (state.connectionState == value) {
      // Nothing more to do
      return;
    }

    add(NewDeviceStateEvent(connectionState: value));
  }

  /// Called when the [BondState] of the [state.device] is updated
  void _onNewBondState(BondState value) {
    if (state.bondState == value) {
      // Nothing more to do
      return;
    }

    add(NewDeviceStateEvent(bondState: value));
  }

  /// Called when the [NewDeviceStateEvent] event is emitted
  ///
  /// This method manages the devices states update
  void _onNewDeviceStateEvent(
    NewDeviceStateEvent event,
    Emitter<BleConnectToDeviceState> emitter,
  ) =>
      emitter(BleDeviceUpdateState(
        previousState: state,
        bondState: event.bondState,
        connectionState: event.connectionState,
      ));

  /// Called when the [DisconnectDeviceEvent] event is emitted
  ///
  /// This method manages the disconnection to the currently connected device
  Future<void> _onDisconnectDeviceEvent(
    DisconnectDeviceEvent event,
    Emitter<BleConnectToDeviceState> emitter,
  ) =>
      _connectionMutex.protect(() async {
        await _focusOnNewDevice(null);
        emitter(BleDeviceDisconnectState(previousState: state));
      });

  /// Called when the bloc is closing
  @override
  Future<void> close() async {
    final futures = <Future>[];

    if (_connectionSub != null) {
      futures.add(_connectionSub!.cancel());
    }

    if (_bondStateSub != null) {
      futures.add(_bondStateSub!.cancel());
    }

    if (_connectionMutex.isLocked) {
      await _connectionMutex.acquire();
      _connectionMutex.release();
    }

    await Future.wait(futures);

    await super.close();
  }
}
