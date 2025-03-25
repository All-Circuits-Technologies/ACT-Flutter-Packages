// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_ble_manager/src/ble_manager.dart';
import 'package:act_ble_manager/src/data/constants.dart' as ble_constants;
import 'package:act_ble_manager/src/data/error_messages.dart' as error_messages;
import 'package:act_ble_manager/src/models/ble_device.dart';
import 'package:act_ble_manager/src/types/bond_state.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mutex/mutex.dart';

/// Manages the connection to BLE device in the GATT part
class BleGattConnectService extends AbsWithLifeCycle {
  /// The flutter BLE lib instance
  final FlutterReactiveBle _flutterBle;

  /// The BLE manager
  final BleManager _bleManager;

  /// Mutex used to manage concurrency inside BLE manager
  final Mutex _bleMutex;

  /// This controller is used to emit a new [BleDevice] when it's connected
  /// This emits null, when we are disconnected from the device.
  final StreamController<BleDevice?> _lastConnectedStreamCtrl;

  /// Last connected device
  BleDevice? _lastConnectedDevice;

  /// Returns the last connected device
  BleDevice? get lastConnectedDevice => _lastConnectedDevice;

  /// This stream emits the new last connected device
  /// This emits null, when we are disconnected from the device.
  Stream<BleDevice?> get lastConnectedDeviceStream => _lastConnectedStreamCtrl.stream;

  /// Connection state controller
  StreamSubscription<DeviceConnectionState>? _deviceConnectionSub;

  /// Class constructor
  BleGattConnectService({
    required FlutterReactiveBle flutterReactiveBle,
    required BleManager bleManager,
    required Mutex bleMutex,
  })  : _flutterBle = flutterReactiveBle,
        _bleManager = bleManager,
        _bleMutex = bleMutex,
        _lastConnectedStreamCtrl = StreamController.broadcast();

  /// {@template act_ble_manager.BleGattConnectService.connect}
  /// Connect to [device] and discovers its services and characteristics.
  ///
  /// A callback [onLowLevelConnect] can be given to the function, it is called
  /// just after the low-level connection and before services discovery
  ///
  /// The call is protected by a mutex [_bleMutex].
  /// {@endtemplate}
  Future<bool> connect(
    BleDevice device, {
    VoidCallback? onLowLevelConnect,
  }) =>
      _bleMutex.protect(() async {
        if (!(await _bleManager.checkAndAskForPermissionsAndServices())) {
          // This test manage the case where the user haven't accepted the BLE permissions or BLE is
          // not activated on phone
          _bleManager.logsHelper.w("The user don't have accepted the BLE permission or Ble isn't "
              "activated on the phone; therefore we can't connect");
          return false;
        }

        await _disconnectWithoutMutex();

        await _tryToCleanGattCache(device: device);

        device.bondState = BondState.unknown;
        if (!(await _manageLowLevelConnection(device))) {
          return false;
        }

        if (onLowLevelConnect != null) {
          onLowLevelConnect();
        }

        _setLastConnectedDevice(device);
        _deviceConnectionSub =
            _lastConnectedDevice!.connectionStateStream.listen(_onDeviceConnectionChanged);

        // Find services and characteristics
        List<Service>? services;

        do {
          try {
            await _flutterBle.discoverAllServices(device.id);
            services = await _flutterBle.getDiscoveredServices(device.id);
            device.bondState = BondState.bonded;
          } catch (error) {
            var bondedState = BondState.bonded;

            _bleManager.logsHelper.w('An error occurred when tried to discover the services of '
                'device: ${device.id}, error: $error');
            services = null;

            // Verify if error comes from bonding
            if (error is PlatformException && error.message != null) {
              if (error.message!.contains(error_messages.bondingErrorMessage)) {
                _bleManager.logsHelper.i("Device bonding is in progress");
                bondedState = BondState.bonding;
              }
            }

            device.bondState = bondedState;
          }

          if (device.bondState == BondState.bonding) {
            // We wait some times before retesting
            await Future.delayed(const Duration(seconds: 2));
          }
        } while (device.bondState == BondState.bonding);

        if (services == null) {
          return false;
        }

        device.updateServicesAndChar(services);

        return true;
      });

  /// This method manages the connection of a [BleDevice] to the BLE lib
  /// Because the connection may fail, this try multiple times the connection
  /// before considering that a problem occurred
  Future<bool> _manageLowLevelConnection(BleDevice device) async {
    final elapsedTime = Stopwatch();
    var leftDuration = ble_constants.connectTimeout;

    void calculateLeftDuration() {
      leftDuration = ble_constants.connectTimeout - elapsedTime.elapsed;
    }

    elapsedTime.start();

    while (device.connectionState != DeviceConnectionState.connected && !leftDuration.isNegative) {
      if (!_bleManager.hasPermissions || !_bleManager.isEnabled) {
        _bleManager.logsHelper.w("Can't proceed, we haven't the right to connect with BLE");
        return false;
      }

      // Listen for the device state in order to know if the connection has
      // succeeded or not
      final completer = Completer();

      // The received disconnected can be a rest of a previous connection
      var atLeastOneConnecting = false;

      final connSub = device.connectionStateStream.listen((connState) {
        if (connState == DeviceConnectionState.connecting) {
          _bleManager.logsHelper.d('At least one connected');
          atLeastOneConnecting = true;
        } else if (connState == DeviceConnectionState.connected ||
            (connState == DeviceConnectionState.disconnected && atLeastOneConnecting)) {
          _bleManager.logsHelper.d('Can complete: $connState, at least one connecting: '
              '$atLeastOneConnecting');
          completer.complete();
        }
      });

      Stream<ConnectionStateUpdate>? connectionStream;
      _bleManager.logsHelper.d('Try to connect to device: ${device.id}');
      try {
        connectionStream = _flutterBle.connectToDevice(
          id: device.id,
          connectionTimeout: ble_constants.lowLevelConnectTimeout,
        );
      } catch (e) {
        _bleManager.logsHelper.w('The connection of the device: ${device.id}, failed: $e');
      }

      if (connectionStream == null) {
        _bleManager.logsHelper.d('The connection fails but we will retry');
        // The connection fails but we will retry
        await connSub.cancel();
        continue;
      }

      await device.setConnectionStream(connectionStream);

      if (device.connectionState == DeviceConnectionState.connected) {
        _bleManager.logsHelper.d('Device is connected, leave the loop');
        // Device is connected, leave the loop
        await connSub.cancel();
        continue;
      }

      // Calculate the left duration
      calculateLeftDuration();

      // Wait to receive a connected or disconnected event
      await completer.future.timeout(ble_constants.lowLevelConnectTimeout, onTimeout: () {
        _bleManager.logsHelper.w("The device ${device.id} isn't connected: "
            "${device.connectionState}, and the timeout raised");
      });

      if (device.connectionState != DeviceConnectionState.connected) {
        // If the device isn't connected, we force the disconnection
        _bleManager.logsHelper.d("If the device isn't connected, we force the disconnection");
        await device.disconnect();

        //We wait some times before retrying
        await Future.delayed(ble_constants.lowLevelConnectTimeout);
      }

      await connSub.cancel();

      // Calculate the left duration
      calculateLeftDuration();
    }

    return (device.connectionState == DeviceConnectionState.connected);
  }

  /// We try to clean the GATT cache of the connected device
  ///
  /// Most of the time, the device is disconnected; therefore this won't work. Nevertheless, cases
  /// may happen where Android have kept opened connection to the device (but those connections
  /// are no more used). By this method, we try to remove them.
  Future<void> _tryToCleanGattCache({required BleDevice device}) async {
    if (globalGetIt().get<PlatformManager>().isIos) {
      // Nothing to do here: in iOS you can't clear GATT cache
      return;
    }

    try {
      await _flutterBle.clearGattCache(device.id);
    } catch (error) {
      if (error.toString().contains(error_messages.clearCacheDeviceNotConnected)) {
        // This case is normal, because most of the time the device isn't connected here. What we
        // want to manage is case where the element is still connected and that causes problems
      } else {
        _bleManager.logsHelper.e("A problem occurred when tried to clear the gatt cache linked to "
            "the device id: ${device.id}, error: $error");
      }
    }
  }

  /// Called when the device connection changed
  Future<void> _onDeviceConnectionChanged(DeviceConnectionState deviceState) async {
    if (deviceState == DeviceConnectionState.disconnected) {
      await _deviceConnectionSub?.cancel();
      _deviceConnectionSub = null;
      _setLastConnectedDevice(null);
    }
  }

  /// {@template act_ble_manager.BleGattConnectService.disconnect}
  /// Disconnect the current device
  ///
  /// The call is protected by a mutex [_bleMutex].
  /// {@endtemplate}
  Future<void> disconnect() async => _bleMutex.protect(_disconnectWithoutMutex);

  /// This allow to disconnect without testing the BLE mutex
  Future<void> _disconnectWithoutMutex() async {
    if (_lastConnectedDevice != null) {
      await _lastConnectedDevice?.disconnect();
    }
  }

  /// Set the last connected device
  ///
  /// [value] is null when we are disconnected from the precedent device.
  void _setLastConnectedDevice(BleDevice? value) {
    if (value != _lastConnectedDevice) {
      _lastConnectedDevice = value;
      _lastConnectedStreamCtrl.add(value);
    }
  }

  /// Manage the disposing of the service
  @override
  Future<void> disposeLifeCycle() async {
    final futuresList = <Future>[
      _lastConnectedStreamCtrl.close(),
    ];

    if (_deviceConnectionSub != null) {
      futuresList.add(_deviceConnectionSub!.cancel());
    }

    await Future.wait(futuresList);

    return super.disposeLifeCycle();
  }
}
