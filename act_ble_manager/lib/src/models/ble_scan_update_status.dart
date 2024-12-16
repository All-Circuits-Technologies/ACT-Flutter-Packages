// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/src/models/ble_scanned_device.dart';

/// Bluetooth scan device status
class BleScanUpdateStatus {
  final BleScanUpdateType type;
  final BleScannedDevice device;

  BleScanUpdateStatus(this.type, this.device);
}

/// BLE scan update type
enum BleScanUpdateType {
  addDevice,
  removeDevice,
  updateDevice,
}
