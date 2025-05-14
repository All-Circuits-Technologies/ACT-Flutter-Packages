// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// This represents a JWT token and its important information
class TokenInfo extends Equatable {
  /// The stringified token
  final String token;

  /// The expiration date of the token
  final DateTime? tokenExpDate;

  /// Check if the token is valid or not
  bool get isValid =>
      token.isNotEmpty &&
      (tokenExpDate == null || (tokenExpDate!.compareTo(DateTime.now().toUtc()) > 0));

  /// Class constructor
  const TokenInfo({
    required this.token,
    this.tokenExpDate,
  });

  /// Copy the current token and update the given elements
  TokenInfo copyWith({
    String? token,
    DateTime? tokenExpDate,
    bool forceTokenExpDate = false,
  }) =>
      TokenInfo(
          token: token ?? this.token,
          tokenExpDate: tokenExpDate ?? (forceTokenExpDate ? null : tokenExpDate));

  /// Equatable properties
  @override
  List<Object?> get props => [token, tokenExpDate];
}
