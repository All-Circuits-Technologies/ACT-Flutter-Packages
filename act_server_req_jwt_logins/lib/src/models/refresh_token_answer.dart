// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_jwt_logins/src/models/token_answer.dart';

/// Contains the refresh token answer
class RefreshTokenAnswer extends TokenAnswer {
  /// The refresh JWT
  final String refreshToken;

  /// The refresh JWT payload
  final Map<String, dynamic> refreshPayload;

  /// Get the "exp" value of the refresh token payload
  int? get refreshExpInMs {
    final value = refreshPayload[TokenAnswer.expirationTimePayloadFieldKey];

    if (value == null || value is! int) {
      return null;
    }

    // The standard defined that the "exp" field is second since epochs, that's why multiply it by
    // 1000 to have milliseconds
    return value * 1000;
  }

  /// Class constructor
  const RefreshTokenAnswer({
    required super.token,
    required super.payload,
    required this.refreshToken,
    required this.refreshPayload,
  });

  @override
  List<Object?> get props => [...super.props, refreshToken, refreshPayload];
}
