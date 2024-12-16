// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Contains the token answer
class TokenAnswer extends Equatable {
  /// Payload key of the expiration time payload field "exp"
  static const expirationTimePayloadFieldKey = "exp";

  /// The JWT
  final String token;

  /// The JWT payload
  final Map<String, dynamic> payload;

  /// Get the "exp" value of the token payload
  int? get expInMs {
    final value = payload[expirationTimePayloadFieldKey];

    if (value == null || value is! int) {
      return null;
    }

    return value * 1000;
  }

  /// Class constructor
  const TokenAnswer({required this.token, required this.payload});

  @override
  List<Object?> get props => [token, payload];
}
