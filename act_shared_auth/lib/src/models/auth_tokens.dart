// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/src/models/auth_token.dart';
import 'package:equatable/equatable.dart';

/// Represents useful elements linked to user authentication.
///
/// It can be used to represents a JWT and a refresh JWT, but also OAuth tokens with id token.
class AuthTokens extends Equatable {
  /// This is the key used to stringify or parse the access token from a JSON object
  static const _accessTokenKey = "accessToken";

  /// This is the key used to stringify or parse the refresh token from a JSON object
  static const _refreshTokenKey = "refreshToken";

  /// This is the key used to stringify or parse the id token from a JSON object
  static const _idTokenKey = "idToken";

  /// This is the access token used to verify the user on server.
  final AuthToken? accessToken;

  /// This is the refresh token used to ask a new [accessToken] from the provider server.
  final AuthToken? refreshToken;

  /// With OAuth 2 this is used to identify an user and contains useful information
  final String? idToken;

  /// Class constructor
  const AuthTokens({
    this.accessToken,
    this.refreshToken,
    this.idToken,
  });

  /// Copy the current tokens and update the given elements
  AuthTokens copyWith({
    AuthToken? accessToken,
    bool forceAccessTokenValue = false,
    AuthToken? refreshToken,
    bool forceRefreshTokenValue = false,
    String? idToken,
    bool forceIdTokenValue = false,
  }) =>
      AuthTokens(
        accessToken: accessToken ?? (forceAccessTokenValue ? null : this.accessToken),
        refreshToken: refreshToken ?? (forceRefreshTokenValue ? null : this.refreshToken),
        idToken: idToken ?? (forceIdTokenValue ? null : this.idToken),
      );

  /// Transform the element to a JSON object
  Map<String, dynamic> toJson() => {
        if (accessToken != null) _accessTokenKey: accessToken!.toJson(),
        if (refreshToken != null) _refreshTokenKey: refreshToken!.toJson(),
        if (idToken != null) _idTokenKey: idToken,
      };

  /// Parse the given [json] to a [AuthTokens] object
  static AuthTokens? fromJson(Map<String, dynamic> json) {
    final accessTokenResult = JsonUtility.getOneElement<AuthToken, Map<String, dynamic>>(
      json: json,
      key: _accessTokenKey,
      canBeUndefined: true,
      castValueFunc: AuthToken.fromJson,
      loggerManager: appLogger(),
    );

    final refreshTokenResult = JsonUtility.getOneElement<AuthToken, Map<String, dynamic>>(
      json: json,
      key: _refreshTokenKey,
      canBeUndefined: true,
      castValueFunc: AuthToken.fromJson,
      loggerManager: appLogger(),
    );

    final idTokenResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _idTokenKey,
      canBeUndefined: true,
      loggerManager: appLogger(),
    );

    if (!accessTokenResult.isOk || !refreshTokenResult.isOk || !idTokenResult.isOk) {
      appLogger()
          .w("A problem occurred when tried to get the authentication tokens from the given JSON");
      return null;
    }

    return AuthTokens(
      accessToken: accessTokenResult.value,
      refreshToken: refreshTokenResult.value,
      idToken: idTokenResult.value,
    );
  }

  /// Object properties
  @override
  List<Object?> get props => [accessToken, refreshToken, idToken];
}
