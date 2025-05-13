import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:equatable/equatable.dart';

class AuthToken extends Equatable {
  static const _rawKey = "raw";

  static const _expirationKey = "expiration";

  final String raw;

  final DateTime? expiration;

  const AuthToken({
    required this.raw,
    this.expiration,
  });

  AuthToken copyWith({
    String? raw,
    DateTime? expiration,
    bool forceExpirationValue = false,
  }) =>
      AuthToken(
        raw: raw ?? this.raw,
        expiration: expiration ?? (forceExpirationValue ? null : this.expiration),
      );

  Map<String, dynamic> toJson() => {
        _rawKey: raw,
        if (expiration != null) _expirationKey: expiration?.millisecondsSinceEpoch,
      };

  /// Check if the token is valid or not
  bool get isValid =>
      raw.isNotEmpty && (expiration == null || (expiration!.compareTo(DateTime.now().toUtc()) > 0));

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
      castValueFunc: (toCast) => DateTime.fromMillisecondsSinceEpoch(toCast, isUtc: true),
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

  static AuthToken? fromJwtToken(String token) {
    final jwt = JwtParserUtility.tryToParseToken(token);
    if (jwt == null) {
      return null;
    }

    final expResult = JwtParserUtility.getExpiration(jwt);
    if (!expResult.isOk) {
      return null;
    }

    return AuthToken(raw: token, expiration: expResult.exp);
  }

  @override
  List<Object?> get props => [raw, expiration];
}
