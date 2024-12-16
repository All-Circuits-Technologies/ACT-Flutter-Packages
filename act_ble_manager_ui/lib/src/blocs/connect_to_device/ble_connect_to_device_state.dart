// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This the abstract class of all the [BleConnectToDeviceBloc] states
///
/// We could have directly used the [bondState] and [connectionState] from the [device] instead
/// of storing those information in the state, but when the update of those states are fast, the
/// view might loose some information.
/// For instance, when we connect to a device, the device emits a connecting state which fire a new
/// [BleConnectToDeviceState] in the bloc, but while flutter is rebuilding the view the device is
/// now connected. Therefore when we will read the connection state it will be
/// [DeviceConnectionState.connected]. Therefore, you will be loosing the connecting state.
/// We do the choice to display all the states to the view, which can manage by itself thresholds.
abstract class BleConnectToDeviceState extends Equatable {
  /// True when we enter in the BLE device connection process
  final bool loading;

  /// This is the device we are interacting with.
  /// If not null, the device may have a [connectionState] equals to
  /// [DeviceConnectionState.disconnected]
  /// If null, we are not connected to a device.
  ///
  /// The better way to know if we are connected to a device or not, it's to verify the value of
  /// [connectionState].
  final BleDevice? device;

  /// The current [bondState] of the device. If we aren't connected to a device, this state is
  /// equals to [BondState.unknown]
  final BondState bondState;

  /// The current [connectionState] of the device. If we aren't connected to a device, this state is
  /// equals to [DeviceConnectionState.disconnected]
  final DeviceConnectionState connectionState;

  /// True if we tried to connect in this view to a device and it has failed.
  /// This only works if the user tried to connect to the device through the
  /// [ChooseDeviceToConnectToEvent] event
  final bool isConnectionFailed;

  /// True if we are trying to connect to a new device.
  ///
  /// The connecting value is returned from the BleDevice we are connecting to and it may take some
  /// times to get the value.
  /// Loading is equals to true when we call the connect method.
  /// Therefore to listen the connecting status and loading give us a better feedback on the
  /// connection process
  bool get isLoadingOrConnecting => loading || connectionState == DeviceConnectionState.connecting;

  /// Class constructor
  BleConnectToDeviceState({
    required BleConnectToDeviceState previousState,
    bool? loading,
    BleDevice? device,
    bool forceDeviceValue = false,
    BondState? bondState,
    DeviceConnectionState? connectionState,
    bool? isConnectionFailed,
  })  : loading = loading ?? previousState.loading,
        device = device ?? (forceDeviceValue ? null : previousState.device),
        bondState = bondState ?? previousState.bondState,
        connectionState = connectionState ?? previousState.connectionState,
        isConnectionFailed = isConnectionFailed ?? previousState.isConnectionFailed,
        super();

  /// Init class constructor
  const BleConnectToDeviceState.init()
      : loading = false,
        device = null,
        bondState = BondState.unknown,
        connectionState = DeviceConnectionState.disconnected,
        isConnectionFailed = false;

  /// State class properties
  @mustCallSuper
  @override
  List<Object?> get props => [
        loading,
        device?.id,
        connectionState,
        bondState,
        isConnectionFailed,
      ];
}

/// Init state of the bloc
class InitBleConnectToDeviceState extends BleConnectToDeviceState {
  /// Class constructor
  const InitBleConnectToDeviceState() : super.init();
}

/// This state is called when the user has explicitly asked to connect to a device
///
/// We get the [connectionState] and [bondState] values from the device itself.
/// We also reinit the [isConnectionFailed] state.
class BleNewDeviceState extends BleConnectToDeviceState {
  /// Class constructor
  BleNewDeviceState({
    required super.previousState,
    required BleDevice super.device,
  }) : super(
          isConnectionFailed: false,
          connectionState: device.connectionState,
          bondState: device.bondState,
        );
}

/// This state is called when we call the connection method
class LoadingConnectState extends BleConnectToDeviceState {
  /// Class constructor
  LoadingConnectState({
    required super.previousState,
    required bool super.loading,
  }) : super();
}

/// This state is called when the connection to the device, asked by the user, has failed
class BleConnectionFailedState extends BleConnectToDeviceState {
  /// Class constructor
  BleConnectionFailedState({
    required super.previousState,
  }) : super(
          isConnectionFailed: true,
          loading: false,
        );
}

/// This state is called when the user asked to disconnect from the currently connected device
class BleDeviceDisconnectState extends BleConnectToDeviceState {
  /// Class constructor
  BleDeviceDisconnectState({
    required super.previousState,
  }) : super(
          forceDeviceValue: true,
          device: null,
          connectionState: DeviceConnectionState.disconnected,
          bondState: BondState.unknown,
        );
}

/// This state is called when the device we are connected with, update its states
class BleDeviceUpdateState extends BleConnectToDeviceState {
  /// Class constructor
  BleDeviceUpdateState({
    required super.previousState,
    super.bondState,
    super.connectionState,
  });
}
