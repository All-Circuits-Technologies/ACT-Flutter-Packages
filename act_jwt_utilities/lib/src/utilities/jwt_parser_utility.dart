import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_jwt_utilities/src/data/jwt_keys_constant.dart' as jwt_keys_constant;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

sealed class JwtParserUtility {
  static JWT? tryToParseToken(String token) {
    JWT? jwt;
    try {
      jwt = JWT.decode(token);
    } catch (error) {
      appLogger().w("An error occurred when tried to decode the given token: $error");
    }

    return jwt;
  }

  static bool isTokenValid(JWT token) {
    final expResult = getExpiration(token);
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

  static ({bool isOk, DateTime? exp}) getExpiration(JWT token) {
    final payload = token.payload;
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

    return (isOk: true, exp: DateTime.fromMillisecondsSinceEpoch(expirationTs, isUtc: true));
  }

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

  static ({bool isOk, DateTime? exp}) getExpirationFromString(String token) {
    final jwt = tryToParseToken(token);
    if (jwt == null) {
      // The token parsing has failed
      appLogger().w("The token given isn't a JWT, we can't get the expiration dateTime");
      return const (isOk: false, exp: null);
    }

    return getExpiration(jwt);
  }
}
