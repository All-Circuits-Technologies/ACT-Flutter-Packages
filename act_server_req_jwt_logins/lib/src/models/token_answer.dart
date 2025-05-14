// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_jwt_logins/act_server_req_jwt_logins.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

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

  /// Transform the current token answer to [TokenInfo]
  TokenInfo toTokenInfo() => TokenInfo(
        token: token,
        tokenExpDate: parseExpData(expInMs),
      );

  /// Parse the expiration date from milliseconds since epoch to date time
  @protected
  static DateTime? parseExpData(int? expInMs) {
    if (expInMs == null) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(expInMs, isUtc: true);
  }

  /// Try to parse a JWT from [token]
  ///
  /// Returns null if a problem occurred
  static TokenAnswer? tryToParseJwtToken(
    String token, {
    LogsHelper? logsHelper,
  }) {
    final jwt = JWT.tryDecode(token);
    if (jwt == null) {
      logsHelper?.w("A problem occurred when tried to decode a given token");
      return null;
    }

    final payload = jwt.payload;
    if (payload is! Map<String, dynamic>) {
      logsHelper?.w("The payload of JWT token isn't a json Map");
      return null;
    }

    return TokenAnswer(token: token, payload: payload);
  }

  /// Properties list
  @override
  List<Object?> get props => [token, payload];
}
