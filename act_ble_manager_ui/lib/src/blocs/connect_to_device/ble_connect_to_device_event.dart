// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This the abstract class of all the [BleConnectToDeviceBloc] events
abstract class BleConnectToDeviceEvent extends Equatable {
  /// Class constructor
  const BleConnectToDeviceEvent();

  /// Properties list of the event
  @mustCallSuper
  @override
  List<Object?> get props => [];
}

/// Emitted when the user wants to connect to a scanned device
class ChooseDeviceToConnectToEvent extends BleConnectToDeviceEvent {
  /// The scanned device to connect to
  final BleScannedDevice deviceToConnectTo;

  /// Class constructor
  const ChooseDeviceToConnectToEvent({
    required this.deviceToConnectTo,
  });

  /// Properties list of the event
  @override
  List<Object?> get props => [
        ...super.props,
        deviceToConnectTo,
      ];
}

/// Emitted when the bond state and/or the connection state have been updated
class NewDeviceStateEvent extends BleConnectToDeviceEvent {
  /// This is the new [BondState] of the device
  /// If null, nothing has changed
  final BondState? bondState;

  /// This is the new [DeviceConnectionState] of the device
  /// If null, nothing has changed
  final DeviceConnectionState? connectionState;

  /// Class constructor
  const NewDeviceStateEvent({
    this.bondState,
    this.connectionState,
  });

  /// Properties list of the event
  @override
  List<Object?> get props => [
        ...super.props,
        bondState,
        connectionState,
      ];
}

/// Emitted when the user wants to disconnect from the currently connected BleDevice
class DisconnectDeviceEvent extends BleConnectToDeviceEvent {
  const DisconnectDeviceEvent();
}
