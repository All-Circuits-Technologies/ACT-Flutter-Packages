// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_tb_extender_auth/src/types/broker_auth_error.dart';
import 'package:equatable/equatable.dart';

/// The typed result of a call to the `POST /api/v1/devices/<serial>/claim` endpoint of the
/// tb-extender broker.
///
/// A call either yields a [BrokerClaimSuccess], which names the device now assigned to the
/// customer of the caller, or a [BrokerClaimFailure], which carries a typed [BrokerAuthError].
sealed class BrokerClaimResult extends Equatable {
  /// Class constructor
  const BrokerClaimResult();
}

/// A claim the broker accepted: the device is assigned to the customer of the caller.
class BrokerClaimSuccess extends BrokerClaimResult {
  /// The ThingsBoard id of the claimed device.
  final String deviceId;

  /// Class constructor
  const BrokerClaimSuccess({required this.deviceId});

  /// Object properties
  @override
  List<Object?> get props => [deviceId];
}

/// A claim which failed, carrying the typed error.
class BrokerClaimFailure extends BrokerClaimResult {
  /// The typed error of the broker.
  final BrokerAuthError error;

  /// Class constructor
  const BrokerClaimFailure(this.error);

  /// Object properties
  @override
  List<Object?> get props => [error];
}
