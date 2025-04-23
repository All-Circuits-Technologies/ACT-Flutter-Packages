// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_jwt_logins/src/models/token_answer.dart';
import 'package:act_server_req_jwt_logins/src/models/token_info.dart';

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

  TokenInfo toRefreshTokenInfo() => TokenInfo(
        token: refreshToken,
        tokenExpDate: TokenAnswer.parseExpData(refreshExpInMs),
      );

  static RefreshTokenAnswer? parseJwtTokens(
      {required String token, required String refreshToken, LogsHelper? logsHelper}) {
    final tokenAns = TokenAnswer.tryToParseJwtToken(token, logsHelper: logsHelper);
    final refreshTokenAns = TokenAnswer.tryToParseJwtToken(refreshToken, logsHelper: logsHelper);

    if (tokenAns == null || refreshTokenAns == null) {
      return null;
    }

    return RefreshTokenAnswer(
        token: token,
        payload: tokenAns.payload,
        refreshToken: refreshToken,
        refreshPayload: refreshTokenAns.payload);
  }

  @override
  List<Object?> get props => [...super.props, refreshToken, refreshPayload];
}
