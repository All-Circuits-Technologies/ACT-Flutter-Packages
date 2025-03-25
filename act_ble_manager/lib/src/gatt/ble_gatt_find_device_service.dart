// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_ble_manager/src/ble_manager.dart';
import 'package:act_ble_manager/src/data/constants.dart' as ble_constants;
import 'package:act_ble_manager/src/gap/ble_gap_service.dart';
import 'package:act_ble_manager/src/models/ble_device.dart';
import 'package:act_ble_manager/src/models/ble_scan_update_status.dart';
import 'package:act_ble_manager/src/models/ble_scanned_device.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Manages the finding of device
class BleGattFindDeviceService extends AbsWithLifeCycle {
  /// The BLE manager
  final BleManager _bleManager;

  /// This is the scan handler linked to the device finding
  late final BleScanHandler _scanHandler;

  /// Class constructor
  BleGattFindDeviceService({
    required BleManager bleManager,
  }) : _bleManager = bleManager;

  /// Called at the service initialization
  @override
  Future<void> initLifeCycle() async {
    _scanHandler = _bleManager.bleGapService.toGenerateScanHandler();
  }

  /// {@template act_ble_manager.BleGattFindDeviceService.isScannedDevice}
  /// Is jacket linked to [id] a scanned device
  /// {@endtemplate}
  bool isScannedDevice(String id) => _scanHandler.isDetected(id);

  /// {@template act_ble_manager.BleGattFindDeviceService.getBleDevice}
  /// Get [BleDevice] from [id], the method will search on scanned devices
  ///
  /// Return null if device has not been scanned
  /// {@endtemplate}
  BleDevice? getBleDevice(String? id) {
    if (id == null) {
      _bleManager.logsHelper.w("The Ble device id given is null, can't get device");
      return null;
    }

    final lastConnectedDevice = _bleManager.bleGattService.lastConnectedDevice;

    if (lastConnectedDevice != null && id == lastConnectedDevice.id) {
      return lastConnectedDevice;
    }

    if (!_scanHandler.isDetected(id)) {
      // The Ble device hasn't been detected
      return null;
    }

    // The null case is managed by the test done upper
    return BleDevice(_scanHandler.getDetectedDevice(id)!);
  }

  /// {@template act_ble_manager.BleGattFindDeviceService.findDeviceByMac}
  /// Find device by [id]
  /// {@endtemplate}
  Future<BleDevice?> findDeviceByMac(String? id) async {
    final device = getBleDevice(id);

    if (device != null && !device.isError()) {
      return device;
    }

    final scannedDevice = await _scanUntilDeviceFound(id!);

    if (scannedDevice == null) {
      return null;
    }

    return BleDevice(scannedDevice);
  }

  /// Try to get device by mac
  Future<BleScannedDevice?> _scanUntilDeviceFound(String id) async {
    final scannedDevice = _scanHandler.getDetectedDevice(id);

    if (scannedDevice != null) {
      return scannedDevice;
    }

    final updateStatus = await WaitUtility.nullableWaitForStatus(
        isExpectedStatus: (scanUpdate) =>
            (scanUpdate.type != BleScanUpdateType.removeDevice && scanUpdate.device.id == id),
        statusEmitter: _scanHandler.scannedDevices,
        timeout: ble_constants.scanOnConnectionDuration,
        doAction: () async => _scanHandler.startScan(scanMode: ScanMode.lowLatency));

    await _scanHandler.stopScan();

    if (updateStatus == null) {
      _bleManager.logsHelper.w("The device: $id hasn't been found in the expected time");
    }

    return updateStatus?.device;
  }

  /// Manage the disposing of the service
  @override
  Future<void> disposeLifeCycle() async {
    await _scanHandler.dispose();

    return super.disposeLifeCycle();
  }
}
