// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This is the abstract state for the [BleScannedDevicesBloc] bloc
abstract class BleScannedDevicesState extends Equatable {
  /// This is equals to true if the scan is active
  /// Please note that this does not necessarily mean what you think it means. This means that the
  /// scan is active and managed by the scan handler.
  ///
  /// But, if the bluetooth is switched off by the user after the start of scanning, the scan
  /// will be stopped internally but it will still be active: the scan handler manages the auto
  /// restart of scanning and when the problem is fixed, you will receive new detected devices.
  /// That's why we have the [isBluetoothActive] property in this BLoC state to inform you when the
  /// user switched off the bluetooth while scanning.
  ///
  /// The property may be false, when we try to start the scan through the handler at start and the
  /// bluetooth, or the permissions, aren't granted. In that case, there is no automatic restart,
  /// you will need to re start the scan manually.
  final bool isScanActive;

  /// True if the bluetooth is switched on or off in the phone
  final bool isBluetoothActive;

  /// Scanned BLE devices list
  final List<BleScannedDevice> devices;

  /// Class constructor
  BleScannedDevicesState({
    required BleScannedDevicesState previousState,
    bool? isScanActive,
    bool? isBluetoothActive,
    List<BleScannedDevice>? devices,
  })  : isScanActive = isScanActive ?? previousState.isScanActive,
        isBluetoothActive = isBluetoothActive ?? previousState.isBluetoothActive,
        devices = devices ?? previousState.devices,
        super();

  /// Init class constructor
  const BleScannedDevicesState.init({
    required this.isBluetoothActive,
  })  : isScanActive = false,
        devices = const [];

  /// State properties
  @mustCallSuper
  @override
  List<Object?> get props => [isScanActive, isBluetoothActive, devices];
}

/// Init state
class InitBleScannedDevicesState extends BleScannedDevicesState {
  /// Class constructor
  const InitBleScannedDevicesState({
    required super.isBluetoothActive,
  }) : super.init();
}

/// Emitted when the handler scan state is updated
class BleScanState extends BleScannedDevicesState {
  /// Class constructor
  BleScanState({
    required super.previousState,
    required super.isScanActive,
  });
}

/// Emitted when a new list of devices is received
class BleUpdateDevicesState extends BleScannedDevicesState {
  /// Class constructor
  ///
  /// To fire a new display of the view, we copy the [devices] list given if it's equal to
  /// [previousState.devices]. Because we fire this state to rebuild the view with an updated list
  BleUpdateDevicesState({
    required super.previousState,
    required List<BleScannedDevice> devices,
  }) : super(
          devices: (previousState.devices == devices) ? List.from(devices) : devices,
        );
}

/// Emitted when the bluetooth phone state is updated
class BluetoothEnableNewState extends BleScannedDevicesState {
  /// Class constructor
  BluetoothEnableNewState({
    required super.previousState,
    required bool super.isBluetoothActive,
  });
}
