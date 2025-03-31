// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// BLE scan update type
enum BleScanUpdateType {
  /// Used when a new BLE device is detected in the scan operation
  addDevice,

  /// Used when a BLE device is no more detected in the scan operation
  removeDevice,

  /// Used when the information of a BLE device are updated in the scan operation
  updateDevice,
}
