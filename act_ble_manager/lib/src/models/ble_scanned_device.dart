// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/src/ble_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// BLE scanned device model
class BleScannedDevice {
  /// Device id
  final String id;

  /// The logs helper linked to the BLE manager
  final LogsHelper _logsHelper;

  /// Device name
  String name;

  /// Timestamp when device is last seen
  DateTime _lastSeenTs;

  /// Timestamp used in scan to know if device is available or not
  DateTime get lastSeenTs => _lastSeenTs;

  /// BLE device constructor
  /// Device state defaults to disconnected
  BleScannedDevice(DiscoveredDevice discoveredDevice)
      : id = discoveredDevice.id,
        name = discoveredDevice.name,
        _lastSeenTs = DateTime.now().toUtc(),
        _logsHelper = globalGetIt().get<BleManager>().logsHelper;

  /// Update the current object with the given [DiscoveredDevice]
  bool updateFromDiscoveredDevice(DiscoveredDevice discoveredDevice) {
    if (discoveredDevice.id != id) {
      _logsHelper.w("Can't update the BleScannedDevice: $id, with the "
          'value of the discovered device: ${discoveredDevice.id}');
      return false;
    }

    name = discoveredDevice.name;
    _lastSeenTs = DateTime.now().toUtc();

    return true;
  }
}
