// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_tb_extender_auth/src/models/broker_login_response.dart';
import 'package:act_tb_extender_auth/src/types/broker_auth_error.dart';
import 'package:equatable/equatable.dart';

/// The typed result of a call to the `POST /api/v1/auth/login` endpoint of the tb-extender broker.
///
/// A call either yields a [BrokerLoginSuccess], which carries the ThingsBoard tokens, or a
/// [BrokerLoginFailure], which carries a typed [BrokerAuthError].
sealed class BrokerLoginResult extends Equatable {
  /// Class constructor
  const BrokerLoginResult();
}

/// A broker login which succeeded, carrying the ThingsBoard tokens and the user information.
class BrokerLoginSuccess extends BrokerLoginResult {
  /// The parsed success payload of the broker.
  final BrokerLoginResponse response;

  /// Class constructor
  const BrokerLoginSuccess(this.response);

  /// Object properties
  @override
  List<Object?> get props => [response];
}

/// A broker login which failed, carrying the typed error and the message of the broker.
class BrokerLoginFailure extends BrokerLoginResult {
  /// The typed error of the broker.
  final BrokerAuthError error;

  /// The message a human reads, when the broker answered one.
  final String? message;

  /// The HTTP status code of the answer of the broker, when an answer was received.
  final int? statusCode;

  /// Class constructor
  const BrokerLoginFailure(this.error, {this.message, this.statusCode});

  /// Object properties
  @override
  List<Object?> get props => [error, message, statusCode];
}
