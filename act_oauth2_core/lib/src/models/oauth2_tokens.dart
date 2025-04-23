import 'dart:convert';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_req_jwt_logins/act_server_req_jwt_logins.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

class OAuth2Tokens extends Equatable {
  static const _staticLogsCategory = "oauth2Parsing";

  static const _jsonAccessTokenKey = "accessToken";

  static const _jsonAccessTokenExpKey = "accessTokenExp";

  static const _jsonRefreshTokenKey = "refreshToken";

  static const _jsonIdTokenKey = "idToken";

  final TokenInfo? accessToken;

  final TokenInfo? refreshToken;

  final String? idToken;

  const OAuth2Tokens({
    required this.accessToken,
    required this.refreshToken,
    required this.idToken,
  });

  const OAuth2Tokens.init() : accessToken = null, refreshToken = null, idToken = null;

  OAuth2Tokens copyWith({
    TokenInfo? accessToken,
    bool forceAccessToken = false,
    TokenInfo? refreshToken,
    bool forceRefreshToken = false,
    String? idToken,
    bool forceIdToken = false,
  }) => OAuth2Tokens(
    accessToken: accessToken ?? (forceAccessToken ? null : this.accessToken),
    refreshToken: refreshToken ?? (forceRefreshToken ? null : this.refreshToken),
    idToken: idToken ?? (forceIdToken ? null : this.idToken),
  );

  OAuth2Tokens copyAndClear() =>
      copyWith(forceAccessToken: true, forceIdToken: true, forceRefreshToken: true);

  ({bool isOk, OAuth2Tokens newValue}) parseTokenResponseAndCopy({
    required TokenResponse response,
    required LogsHelper logsHelper,
  }) => _parseTokensAndCreate(
    accessToken: response.accessToken,
    accessTokenExp: response.accessTokenExpirationDateTime,
    refreshToken: response.refreshToken,
    idToken: idToken,
    logsHelper: logsHelper,
    initTokens: this,
  );

  Map<String, dynamic> toJson() => {
    if (accessToken != null) _jsonAccessTokenKey: accessToken!.token,
    if (accessToken?.tokenExpDate != null)
      _jsonAccessTokenExpKey: accessToken!.tokenExpDate!.millisecondsSinceEpoch,
    if (refreshToken != null) _jsonRefreshTokenKey: refreshToken!.token,
    if (idToken != null) _jsonIdTokenKey: idToken,
  };

  @override
  String toString() => jsonEncode(toJson());

  static String parseToString(OAuth2Tokens tokens) => tokens.toString();

  static OAuth2Tokens? fromJson(Map<String, dynamic> json, {required LogsHelper logsHelper}) {
    if (json.isEmpty) {
      // No tokens in memory
      return const OAuth2Tokens.init();
    }

    final tokenResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _jsonAccessTokenKey,
      canBeUndefined: true,
      loggerManager: appLogger(),
    );

    final accessTokenExpResult = JsonUtility.getOnePrimaryElement<int>(
      json: json,
      key: _jsonAccessTokenExpKey,
      canBeUndefined: true,
      loggerManager: appLogger(),
    );

    final refreshTokenResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _jsonRefreshTokenKey,
      canBeUndefined: true,
      loggerManager: appLogger(),
    );
    final idTokenResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _jsonIdTokenKey,
      canBeUndefined: true,
      loggerManager: appLogger(),
    );

    if (!tokenResult.isOk ||
        !accessTokenExpResult.isOk ||
        !refreshTokenResult.isOk ||
        !idTokenResult.isOk) {
      appLogger().w("A problem occurred when tried to get the OAuth2 tokens from the JSON");
      return null;
    }

    DateTime? accessTokenExp;
    if (accessTokenExpResult.value != null) {
      accessTokenExp = DateTime.fromMillisecondsSinceEpoch(
        accessTokenExpResult.value!,
        isUtc: true,
      );
    }

    final result = _parseTokensAndCreate(
      accessToken: tokenResult.value,
      accessTokenExp: accessTokenExp,
      refreshToken: refreshTokenResult.value,
      idToken: idTokenResult.value,
      logsHelper: logsHelper,
    );

    if (!result.isOk) {
      appLogger().w("A problem occurred when tried to parse the OAuth2 tokens from the JSON");
      return null;
    }

    return result.newValue;
  }

  static OAuth2Tokens? fromStringifiedJson(String? value) {
    if (value == null) {
      return null;
    }

    final logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _staticLogsCategory);

    Map<String, dynamic>? json;
    try {
      final decodedJson = jsonDecode(value);
      if (decodedJson is Map<String, dynamic>) {
        json = decodedJson;
      } else {
        logsHelper.w("The OAuth2 stringified json got isn't a JSON Object");
      }
    } catch (error) {
      logsHelper.e("An error occurred when tried to decode a OAuth2 stringified json");
    }

    if (json == null) {
      return null;
    }

    return fromJson(json, logsHelper: logsHelper);
  }

  static ({bool isOk, OAuth2Tokens newValue}) _parseTokensAndCreate({
    required String? accessToken,
    required DateTime? accessTokenExp,
    required String? refreshToken,
    required String? idToken,
    required LogsHelper logsHelper,
    OAuth2Tokens initTokens = const OAuth2Tokens.init(),
  }) {
    var oAuth2Tokens = initTokens.copyWith(idToken: idToken, forceIdToken: true);

    if (accessToken == null) {
      logsHelper.w("The response received doesn't contain an access token, can't proceed");
      return (isOk: false, newValue: oAuth2Tokens);
    }

    oAuth2Tokens = oAuth2Tokens.copyWith(
      accessToken: TokenInfo(token: accessToken, tokenExpDate: accessTokenExp),
    );

    if (refreshToken == null) {
      // Nothing more to do
      return (isOk: true, newValue: oAuth2Tokens);
    }

    oAuth2Tokens = oAuth2Tokens.copyWith(refreshToken: TokenInfo(token: refreshToken));
    return (isOk: true, newValue: oAuth2Tokens);
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, idToken];
}
