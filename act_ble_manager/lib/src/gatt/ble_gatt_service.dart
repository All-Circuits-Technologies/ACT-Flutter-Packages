// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_ble_manager/src/ble_manager.dart';
import 'package:act_ble_manager/src/gatt/ble_gatt_characteristic_service.dart';
import 'package:act_ble_manager/src/gatt/ble_gatt_connect_service.dart';
import 'package:act_ble_manager/src/gatt/ble_gatt_find_device_service.dart';
import 'package:act_ble_manager/src/models/ble_device.dart';
import 'package:act_ble_manager/src/types/characteristics_error.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mutex/mutex.dart';

/// Manages all the GATT features
class BleGattService extends AbstractService {
  /// This service manages the connect part of the GATT features
  late final BleGattConnectService _connectService;

  /// This service manages the finding of devices in the GATT features
  late final BleGattFindDeviceService _findDeviceService;

  /// This service manages the characteristics in the GATT features
  late final BleGattCharacteristicService _characteristicService;

  /// Mutex used to manage concurrency inside BLE manager
  final Mutex _bleMutex;

  /// Returns the last connected device
  BleDevice? get lastConnectedDevice => _connectService.lastConnectedDevice;

  /// Class constructor
  BleGattService({
    required FlutterReactiveBle flutterReactiveBle,
    required BleManager bleManager,
  }) : _bleMutex = Mutex() {
    _connectService = BleGattConnectService(
      flutterReactiveBle: flutterReactiveBle,
      bleManager: bleManager,
      bleMutex: _bleMutex,
    );

    _findDeviceService = BleGattFindDeviceService(bleManager: bleManager);

    _characteristicService = BleGattCharacteristicService(
      flutterReactiveBle: flutterReactiveBle,
      bleManager: bleManager,
      bleMutex: _bleMutex,
    );
  }

  /// Called at the service initialization
  @override
  Future<void> initService() async {
    await _connectService.initService();
    await _findDeviceService.initService();
    await _characteristicService.initService();
  }

  /// Called when the views system is initialized
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    // In that case, the build context can be accessed through async method
    // ignore: use_build_context_synchronously
    await _connectService.initAfterView(context);
    // ignore: use_build_context_synchronously
    await _findDeviceService.initAfterView(context);
    // ignore: use_build_context_synchronously
    await _characteristicService.initAfterView(context);
  }

  /// Connect to [device] and discovers its services and characteristics.
  ///
  /// A callback [onLowLevelConnect] can be given to the function, it is called
  /// just after the low-level connection and before services discovery
  Future<bool> connect(
    BleDevice device, {
    VoidCallback? onLowLevelConnect,
  }) =>
      _connectService.connect(device, onLowLevelConnect: onLowLevelConnect);

  /// Disconnect from [connectedJacket].
  Future<void> disconnect() => _connectService.disconnect();

  /// Is jacket linked to [id] a scanned device
  bool isScannedDevice(String id) => _findDeviceService.isScannedDevice(id);

  /// Get [BleDevice] from [id], the method will search on scanned devices
  ///
  /// Return null if device has not been scanned
  BleDevice? getBleDevice(String? id) => _findDeviceService.getBleDevice(id);

  /// Find device by [id]
  Future<BleDevice?> findDeviceByMac(String? id) => _findDeviceService.findDeviceByMac(id);

  /// Write [values] to characteristic from [uuid]
  Future<CharacteristicsError> writeBleCharacteristic(
    BleDevice device,
    String uuid,
    List<int> values, {
    bool withoutResponse = false,
  }) =>
      _characteristicService.writeBleCharacteristic(
        device,
        uuid,
        values,
        withoutResponse: withoutResponse,
      );

  /// Read characteristic from [uuid]
  /// Return value read
  Future<(CharacteristicsError, List<int>?)> readBleCharacteristic(
    BleDevice device,
    String uuid,
  ) =>
      _characteristicService.readBleCharacteristic(device, uuid);

  /// Set notification on characteristic from [uuid]
  /// Return success
  Future<(CharacteristicsError, Stream<List<int>>?)> subscribeBleNotification(
    BleDevice device,
    String uuid,
  ) =>
      _characteristicService.subscribeBleNotification(device, uuid);

  /// Manage the disposing of the service
  @override
  Future<void> dispose() async {
    final futuresList = <Future>[
      _connectService.dispose(),
      _findDeviceService.dispose(),
      _characteristicService.dispose(),
    ];

    if (_bleMutex.isLocked) {
      await _bleMutex.acquire();
      _bleMutex.release();
    }

    await Future.wait(futuresList);

    return super.dispose();
  }
}
