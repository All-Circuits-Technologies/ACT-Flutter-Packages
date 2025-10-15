// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_jwt_utilities/src/constants/jwt_keys_constant.dart' as jwt_keys_constant;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

/// Contains useful methods to manage JWT tokens
sealed class JwtParserUtility {
  /// This is the separator between the bearer key and the token value
  static const jwtBearerValueSeparator = " ";

  /// Try to parse a JWT token from the given [token] string
  ///
  /// Returns null if a problem occurred in the process
  static JWT? tryToParseToken(String token) {
    JWT? jwt;
    try {
      jwt = JWT.decode(token);
    } catch (error) {
      appLogger().w("An error occurred when tried to decode the given token: $error");
    }

    return jwt;
  }

  /// Test if the given [jwt] is valid and not expired.
  ///
  /// A JWT may not a have an expiration date, in that case, we consider the JWT as valid.
  ///
  /// Return true if the token is valid.
  ///
  /// If [isTsInSeconds] is equals to true, it means that all the timestamps are in seconds.
  /// If [isTsInSeconds] is equals to false, it means that all the timestamps are in milliseconds.
  static bool isTokenValid(JWT jwt, {bool isTsInSeconds = true}) {
    final expResult = getExpiration(jwt: jwt, isTsInSeconds: isTsInSeconds);
    if (!expResult.isOk) {
      appLogger().w(
          "A problem occurred when tried to get the expiration date time from the token, we can't "
          "know if it's valid or not");
      return false;
    }

    if (expResult.exp == null) {
      // The token is valid if there is no expiration date time
      return true;
    }

    return expResult.exp!.compareTo(DateTime.now().toUtc()) >= 0;
  }

  /// Get the expiration date from the given [jwt].
  ///
  /// A JWT may not a have an expiration date, in that case, we return `isOk` equals to true and
  /// `exp` equals to null.
  ///
  /// Returns true in `isOk` parameter if no problem occurred
  ///
  /// If [isTsInSeconds] is equals to true, it means that all the timestamps are in seconds.
  /// If [isTsInSeconds] is equals to false, it means that all the timestamps are in milliseconds.
  static ({bool isOk, DateTime? exp}) getExpiration({required JWT jwt, bool isTsInSeconds = true}) {
    final payload = jwt.payload;
    if (payload is! Map<String, dynamic>) {
      appLogger().w("The JWT payload isn't a map, we can't get the expiration dateTime");
      return const (isOk: false, exp: null);
    }

    final expirationTs = payload[jwt_keys_constant.expirationClaimKey];
    if (expirationTs == null) {
      // A JWT may not contain an expiration date (even if it's strongly not recommended)
      return const (isOk: true, exp: null);
    }

    if (expirationTs is! int) {
      appLogger().w("The token expiration is not an integer, we can't get the expiration dateTime");
      return const (isOk: false, exp: null);
    }

    return (
      isOk: true,
      exp: isTsInSeconds
          ? DateTimeUtility.fromSecondsSinceEpochUtc(expirationTs)
          : DateTimeUtility.fromMillisecondsSinceEpochUtc(expirationTs)
    );
  }

  /// Test if the given token is a valid JWT and not expired.
  ///
  /// The method first tries to parse the [token] as JWT token with [tryToParseToken] method and
  /// then test if the token is valid with [isTokenValid] method.
  ///
  /// If the [token] isn't a valid token or if it's expired, it will return false.
  ///
  /// A JWT may not a have an expiration date, in that case, we consider the JWT as valid.
  static bool isTokenFromStringValid(String? token) {
    if (token == null) {
      // The token is null, nothing more to do
      return false;
    }

    final jwt = tryToParseToken(token);
    if (jwt == null) {
      // The token parsing has failed
      appLogger().w("The token given isn't a JWT, we can't test if it's valid or not");
      return false;
    }

    return isTokenValid(jwt);
  }

  /// Get the expiration date from the given JWT [token].
  ///
  /// The method first tries to parse the [token] as JWT token with [tryToParseToken] method and
  /// then get the expiration date with [getExpiration] method.
  ///
  /// If the [token] isn't a valid token or if a problem occurred in the process it will return
  /// false in the `isOk` returned object.
  ///
  /// If the [token] is valid but it doesn't contain an expiration date, the `isOk` element will be
  /// equal to true and `exp` equals to null.
  ///
  /// If [isTsInSeconds] is equals to true, it means that all the timestamps are in seconds.
  /// If [isTsInSeconds] is equals to false, it means that all the timestamps are in milliseconds.
  static ({bool isOk, DateTime? exp}) getExpirationFromString(String token,
      {bool isTsInSeconds = true}) {
    final jwt = tryToParseToken(token);
    if (jwt == null) {
      // The token parsing has failed
      appLogger().w("The token given isn't a JWT, we can't get the expiration dateTime");
      return const (isOk: false, exp: null);
    }

    return getExpiration(jwt: jwt, isTsInSeconds: isTsInSeconds);
  }

  /// Extract the JWT token from the given [headerValue].
  ///
  /// It doesn't verify the validity of the token.
  ///
  /// The method returns null if the token value can't be retrieved.
  static String? extractJwtFromHeaderValue({
    required String headerValue,
    required String bearerKey,
  }) {
    if (!headerValue.startsWith(bearerKey)) {
      // The header value doesn't start with the bearer key
      return null;
    }

    final tmpValues = headerValue.split(jwtBearerValueSeparator);
    if (tmpValues.length != 2) {
      // The header value doesn't contain the token value
      return null;
    }

    return tmpValues[1];
  }
}
