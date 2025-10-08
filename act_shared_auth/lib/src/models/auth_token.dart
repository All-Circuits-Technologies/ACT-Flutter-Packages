// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:equatable/equatable.dart';

/// Represents a token. The token isn't necessarily a JWT.
class AuthToken extends Equatable {
  /// This is the key used to stringify or parse the raw token from a JSON object
  static const _rawKey = "raw";

  /// This is the key used to stringify or parse the token expiration date from a JSON object
  static const _expirationKey = "expiration";

  /// This is the raw token value as it is received from the provider
  final String raw;

  /// This is the expiration date of the token.
  ///
  /// If null, this means that the token has no expiration.
  final DateTime? expiration;

  /// Class constructor
  const AuthToken({
    required this.raw,
    this.expiration,
  });

  /// Copy the current object and update some elements with the given parameters
  AuthToken copyWith({
    String? raw,
    DateTime? expiration,
    bool forceExpirationValue = false,
  }) =>
      AuthToken(
        raw: raw ?? this.raw,
        expiration: expiration ?? (forceExpirationValue ? null : this.expiration),
      );

  /// Transform the element to a JSON object
  Map<String, dynamic> toJson() => {
        _rawKey: raw,
        if (expiration != null) _expirationKey: expiration?.millisecondsSinceEpoch,
      };

  /// Check if the token is valid or not
  ///
  /// If [expiration] is not null, the method verifies if the date is outdated.
  bool get isValid =>
      raw.isNotEmpty && (expiration == null || (expiration!.compareTo(DateTime.now().toUtc()) > 0));

  /// Parse the auth token from a JSON object
  static AuthToken? fromJson(Map<String, dynamic> json) {
    final raw = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _rawKey,
      loggerManager: appLogger(),
    );

    final expirationResult = JsonUtility.getOneElement<DateTime, int>(
      json: json,
      key: _expirationKey,
      canBeUndefined: true,
      // Because the toJson method store an expiration time in milliseconds, the fromJson must also
      // parse it in milliseconds
      castValueFunc: DateTimeUtility.fromMillisecondsSinceEpochUtc,
      loggerManager: appLogger(),
    );

    if (raw == null || !expirationResult.isOk) {
      appLogger().w("A problem occurred when tried to parse the token from the given JSON");
      return null;
    }

    return AuthToken(
      raw: raw,
      expiration: expirationResult.value,
    );
  }

  /// Parse the [token] as JWT and get the info from it.
  ///
  /// If the [token] is not a JWT, the method will return null.
  ///
  /// If [isTsInSeconds] is equals to true, it means that all the timestamps are in seconds.
  /// If [isTsInSeconds] is equals to false, it means that all the timestamps are in milliseconds.
  static AuthToken? fromJwtToken(String token, {bool isTsInSeconds = true}) {
    final jwt = JwtParserUtility.tryToParseToken(token);
    if (jwt == null) {
      return null;
    }

    final expResult = JwtParserUtility.getExpiration(jwt: jwt);
    if (!expResult.isOk) {
      return null;
    }

    return AuthToken(raw: token, expiration: expResult.exp);
  }

  /// Object properties
  @override
  List<Object?> get props => [raw, expiration];
}
