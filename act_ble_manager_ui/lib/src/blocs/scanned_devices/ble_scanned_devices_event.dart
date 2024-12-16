// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This is the abstract event for the [BleScannedDevicesBloc] bloc
abstract class BleScannedDevicesEvent extends Equatable {
  /// Class constructor
  const BleScannedDevicesEvent();

  /// This is the event properties
  @mustCallSuper
  @override
  List<Object?> get props => [];
}

/// Start scan event to find BLE devices
class StartBleScanEvent extends BleScannedDevicesEvent {
  /// Class constructor
  const StartBleScanEvent();
}

/// Stop scan event
class StopBleScanEvent extends BleScannedDevicesEvent {
  /// Class constructor
  const StopBleScanEvent();
}

/// Clear the scanned devices list
class ClearScannedDevicesListEvent extends BleScannedDevicesEvent {
  /// Class constructor
  const ClearScannedDevicesListEvent();
}

/// Request the permissions and service enabling
class RequestPermsAndServiceEnablingEvent extends BleScannedDevicesEvent {
  /// Class constructor
  const RequestPermsAndServiceEnablingEvent();
}

/// Emitted with the received [BleScanUpdateStatus] from scan handler
class BleScanUpdateStatusEvent extends BleScannedDevicesEvent {
  /// The scan update status
  final BleScanUpdateStatus scanUpdateStatus;

  /// Class constructor
  const BleScanUpdateStatusEvent({
    required this.scanUpdateStatus,
  });

  /// Event properties
  @override
  List<Object?> get props => [scanUpdateStatus, ...super.props];
}

/// Emitted the bluetooth service enabling is updated
class BluetoothEnableStatusEvent extends BleScannedDevicesEvent {
  /// The current bluetooth active status
  final bool isBluetoothActive;

  /// Class constructor
  const BluetoothEnableStatusEvent({
    required this.isBluetoothActive,
  });

  /// Event properties
  @override
  List<Object?> get props => [isBluetoothActive, ...super.props];
}
