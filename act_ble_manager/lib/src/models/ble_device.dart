// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_ble_manager/src/ble_manager.dart';
import 'package:act_ble_manager/src/models/ble_scanned_device.dart';
import 'package:act_ble_manager/src/types/bond_state.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// BLE Device model
class BleDevice {
  /// Device name
  final String name;

  /// Device mac address
  final String id;

  /// Device BLE characteristics
  final List<QualifiedCharacteristic> _characteristics;

  /// Keep BLE connection state
  final StreamController<DeviceConnectionState> _connectionStateCtrl;

  /// This is the stream controller linked to the [BondState] status
  final StreamController<BondState> _bondStateCtrl;

  /// The logs helper linked to the BLE manager
  final LogsHelper _logsHelper;

  /// This is the current [DeviceConnectionState]
  DeviceConnectionState _connectionState;

  /// Device bond state
  BondState _bondState;

  /// Getter of the [_bondState] property
  BondState get bondState => _bondState;

  /// Setter of the [_bondState] property
  set bondState(BondState value) {
    if (value == _bondState) {
      // Nothing to do
      return;
    }

    _bondState = value;
    _bondStateCtrl.add(value);
  }

  /// Stream getter link to the [_bondState] property update
  Stream<BondState> get bondStateStream => _bondStateCtrl.stream;

  /// List of the characteristics linked to the BLE device
  List<QualifiedCharacteristic> get characteristics => _characteristics;

  /// Get the device connection state
  DeviceConnectionState get connectionState => _connectionState;

  /// Sent event when the device connection state changes
  Stream<DeviceConnectionState> get connectionStateStream => _connectionStateCtrl.stream;

  /// This is the connection subscription linked to the listening of the [ConnectionStateUpdate]
  /// state
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;

  /// Abstract BLE device constructor
  /// Device state defaults to disconnected
  BleDevice(BleScannedDevice scannedDevice)
      : name = scannedDevice.name,
        id = scannedDevice.id,
        _bondState = BondState.unknown,
        _connectionStateCtrl = StreamController<DeviceConnectionState>.broadcast(),
        _bondStateCtrl = StreamController<BondState>.broadcast(),
        _connectionState = DeviceConnectionState.disconnected,
        _characteristics = [],
        _logsHelper = globalGetIt().get<BleManager>().logsHelper;

  /// Abstract BLE Device error factory
  BleDevice.error()
      : name = '',
        id = '',
        _bondState = BondState.unknown,
        _connectionStateCtrl = StreamController<DeviceConnectionState>.broadcast(),
        _bondStateCtrl = StreamController<BondState>.broadcast(),
        _connectionState = DeviceConnectionState.disconnected,
        _characteristics = [],
        _logsHelper = globalGetIt().get<BleManager>().logsHelper;

  /// Test if BLE device is on error
  bool isError() => name.isEmpty && id.isEmpty;

  /// This method is useful to register in the object, all the characteristics
  /// linked to the discovered services
  void updateServicesAndChar(List<Service> servicesDiscovered) {
    _characteristics.clear();

    for (final service in servicesDiscovered) {
      _logsHelper.d('Service uuid: $service');
      for (final characteristic in service.characteristics) {
        _characteristics.add(
          QualifiedCharacteristic(
            characteristicId: characteristic.id,
            serviceId: service.id,
            deviceId: id,
          ),
        );
      }
    }
  }

  /// Find the characteristic linked to the [uuid] given
  QualifiedCharacteristic? findCharacteristic(String uuid) {
    for (final char in _characteristics) {
      if (char.characteristicId.toString() == uuid) {
        return char;
      }
    }

    return null;
  }

  /// Set the BLE lib connection stream and link it with this class
  Future<void> setConnectionStream(Stream<ConnectionStateUpdate> connectedStream) async {
    await disconnect();

    _connectionSub = connectedStream.listen(_connectionStateUpdate);
  }

  /// Setter of the connection state, to emit event when the value is updated
  void _setConnectionState(DeviceConnectionState connectionState) {
    if (_connectionState != connectionState) {
      _logsHelper.d('Connection state: $connectionState of device: $id');
      _connectionState = connectionState;
      _connectionStateCtrl.add(connectionState);
    }
  }

  /// Call to disconnect the device from the smartphone
  Future<void> disconnect() async {
    if (_connectionSub == null) {
      // Nothing to do here
      return;
    }

    await _connectionSub?.cancel();
    _connectionSub = null;

    _connectionStateUpdate(
      ConnectionStateUpdate(
        deviceId: id,
        connectionState: DeviceConnectionState.disconnected,
        failure: null,
      ),
    );
  }

  /// Called when the connection state to the BLE device is updated
  void _connectionStateUpdate(ConnectionStateUpdate stateUpdate) {
    if (stateUpdate.deviceId != id) {
      // The device is not concerned by this state
      return;
    }

    if (stateUpdate.failure != null) {
      _logsHelper.w(
          "An error occurred in the process: ${stateUpdate.failure}, state: ${stateUpdate.connectionState}");
      _setConnectionState(DeviceConnectionState.disconnected);
      return;
    }

    if (stateUpdate.connectionState != connectionState) {
      _setConnectionState(stateUpdate.connectionState);
    }
  }

  /// Close stream on remove device
  Future<void> dispose() async {
    final futuresList = <Future>[
      _connectionStateCtrl.close(),
      _bondStateCtrl.close(),
      disconnect(),
    ];

    if (_connectionSub != null) {
      futuresList.add(_connectionSub!.cancel());
    }

    await Future.wait(futuresList);
  }
}
