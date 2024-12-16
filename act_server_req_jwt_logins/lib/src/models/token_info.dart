// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This represents a JWT token and its important information
class TokenInfo {
  /// The stringified token
  String token;

  /// The expiration date of the token
  DateTime? tokenExpDate;

  /// Check if the token is valid or not
  bool get isValid =>
      token.isNotEmpty &&
      (tokenExpDate == null || (tokenExpDate!.compareTo(DateTime.now().toUtc()) > 0));

  /// Class constructor
  TokenInfo({
    required this.token,
    this.tokenExpDate,
  });
}
