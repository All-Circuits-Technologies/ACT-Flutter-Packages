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
class BleGattService extends AbsWithLifeCycle {
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

  /// This stream emits the new last connected device
  /// This emits null, when we are disconnected from the device.
  Stream<BleDevice?> get lastConnectedDeviceStream => _connectService.lastConnectedDeviceStream;

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
  Future<void> initLifeCycle() async {
    await _connectService.initLifeCycle();
    await _findDeviceService.initLifeCycle();
    await _characteristicService.initLifeCycle();
  }

  /// Called when the views system is initialized
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    // In that case, the build context can be accessed through async method
    // ignore: use_build_context_synchronously
    await _connectService.initAfterView(context);
    // In that case, the build context can be accessed through async method
    // ignore: use_build_context_synchronously
    await _findDeviceService.initAfterView(context);
    // In that case, the build context can be accessed through async method
    // ignore: use_build_context_synchronously
    await _characteristicService.initAfterView(context);
  }

  /// {@macro act_ble_manager.BleGattConnectService.connect}
  Future<bool> connect(
    BleDevice device, {
    VoidCallback? onLowLevelConnect,
  }) =>
      _connectService.connect(device, onLowLevelConnect: onLowLevelConnect);

  /// {@macro act_ble_manager.BleGattConnectService.disconnect}
  Future<void> disconnect() => _connectService.disconnect();

  /// {@macro act_ble_manager.BleGattFindDeviceService.isScannedDevice}
  bool isScannedDevice(String id) => _findDeviceService.isScannedDevice(id);

  /// {@macro act_ble_manager.BleGattFindDeviceService.getBleDevice}
  BleDevice? getBleDevice(String? id) => _findDeviceService.getBleDevice(id);

  /// {@macro act_ble_manager.BleGattFindDeviceService.findDeviceByMac}
  Future<BleDevice?> findDeviceByMac(String? id) => _findDeviceService.findDeviceByMac(id);

  /// {@macro act_ble_manager.BleGattCharacteristicService.writeBleCharacteristic}
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

  /// {@macro act_ble_manager.BleGattCharacteristicService.readBleCharacteristic}
  Future<(CharacteristicsError, List<int>?)> readBleCharacteristic(
    BleDevice device,
    String uuid,
  ) =>
      _characteristicService.readBleCharacteristic(device, uuid);

  /// {@macro act_ble_manager.BleGattCharacteristicService.subscribeBleNotification}
  Future<(CharacteristicsError, Stream<List<int>>?)> subscribeBleNotification(
    BleDevice device,
    String uuid,
  ) =>
      _characteristicService.subscribeBleNotification(device, uuid);

  /// Manage the disposing of the service
  @override
  Future<void> dispose() async {
    final futuresList = <Future>[
      _connectService.disposeLifeCycle(),
      _findDeviceService.disposeLifeCycle(),
      _characteristicService.disposeLifeCycle(),
    ];

    if (_bleMutex.isLocked) {
      await _bleMutex.acquire();
      _bleMutex.release();
    }

    await Future.wait(futuresList);

    return super.disposeLifeCycle();
  }
}
