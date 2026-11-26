// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:equatable/equatable.dart';

/// Bluetooth scan device status
class BleScanUpdateStatus extends Equatable {
  /// This is the [BleScanUpdateType] event linked to the [device]
  final BleScanUpdateType type;

  /// This is the [device] concerned by the scan update event
  final BleScannedDevice device;

  /// Class constructor
  const BleScanUpdateStatus(this.type, this.device);

  @override
  List<Object?> get props => [type, device];
}
