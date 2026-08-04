// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_http_client_jwt_auth/act_http_client_jwt_auth.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
// The URLs a requester is built with are not part of the public interface of the package, and there
// is no other way to build one outside of a manager which reaches a real server
// ignore: implementation_imports
import 'package:act_http_client_manager/src/models/server_urls.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The route the tests sign in on.
const aLoginRoute = "/login";

/// The route the tests refresh a token on.
const aRefreshRoute = "/refresh";

/// A token which expires [validFor] from now, and which no server signed.
///
/// The package only ever reads the expiration of a token, so a token which is not signed is enough
/// for a test; a token which expires in the past is what an expired token looks like.
AuthToken aToken({Duration validFor = const Duration(hours: 1), String name = "a token"}) =>
    AuthToken(raw: name, expiration: DateTime.now().toUtc().add(validFor));

/// The server of an application under test, which answers what the test lined up.
///
/// It records the requests it received, which is what a test reads to know which route the login
/// reached and what it sent.
class FakeServerRequester extends ServerRequester {
  /// The status the server answers, per relative route.
  ///
  /// A route which is absent is answered with a success.
  final Map<String, RequestStatus> answers = {};

  /// The requests the server received, in the order it received them.
  final List<RequestParam> requests = [];

  /// Class constructor
  FakeServerRequester()
    : super(
        logsHelper: FakeExternalLogger().buildHelper(category: "test"),
        serverUrls: ServerUrls(defaultUrl: Uri.parse("http://a.server"), byRelRoute: const {}),
        defaultTimeout: const Duration(seconds: 1),
        maxParallelRequestsNb: null,
      );

  /// The relative routes the server was asked for, in the order it was.
  List<String> get routes => requests.map((request) => request.relativeRoute).toList();

  @override
  Future<RequestResponse<ParsedRespBody>> executeRequestWithoutAuth<ParsedRespBody, RespBody>({
    required RequestParam requestParam,
    ParsedRespBody? Function(RespBody body)? parseRespBody,
  }) async {
    requests.add(requestParam);

    return RequestResponse<ParsedRespBody>(
      status: answers[requestParam.relativeRoute] ?? RequestStatus.success,
    );
  }
}

/// The storage of the tokens of a user, kept in memory.
class FakeJwtStorageService with MixinAuthStorageService {
  /// The tokens the storage keeps.
  AuthTokens? storedTokens;

  /// The calls the storage received, in the order it received them.
  final List<String> calls = [];

  /// Class constructor
  FakeJwtStorageService({this.storedTokens});

  /// {@macro act_shared_auth.MixinAuthStorageService.storeTokens}
  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    calls.add("storeTokens()");
    storedTokens = tokens;

    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadTokens}
  @override
  Future<AuthTokens?> loadTokens() async {
    calls.add("loadTokens()");

    return storedTokens;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.clearTokens}
  @override
  Future<void> clearTokens() async {
    calls.add("clearTokens()");
    storedTokens = null;
  }
}

/// The login of an application which signs in with a request of its own.
class FakeJwtLogin extends AbsJwtLogin {
  /// The tokens the server answers when the user signs in, if it answers any.
  AuthTokens? loginAnswer;

  /// Whether the login can build the request which signs the user in.
  bool canBuildLoginRequest;

  /// The number of times the response of the sign in was parsed.
  int parsedLogins = 0;

  /// Class constructor
  FakeJwtLogin({
    required super.serverRequester,
    this.loginAnswer,
    this.canBuildLoginRequest = true,
    super.headerAuthKey,
    super.headerAuthValueFormatted,
    super.verifyTokenExpirationDate,
  }) : super(logsHelper: FakeExternalLogger().buildHelper(category: "test"));

  /// Keeps [tokens] the way the answer of a server does.
  Future<void> keep(AuthTokens tokens) => updateTokenInfo(tokens);

  /// {@macro act_http_client_jwt_auth.AbsJwtLogin.getLoginRequestFromMemory}
  @override
  Future<RequestParam?> getLoginRequestFromMemory() async => canBuildLoginRequest
      ? RequestParam(httpMethod: HttpMethods.post, relativeRoute: aLoginRoute)
      : null;

  /// {@macro act_http_client_jwt_auth.AbsJwtLogin.parseLoginResponse}
  @override
  Future<AuthTokens?> parseLoginResponse(RequestResponse response) async {
    parsedLogins++;

    return loginAnswer;
  }
}

/// The login of an application which refreshes its token rather than signing in again.
class FakeRefreshJwtLogin extends AbsRefreshJwtLogin {
  /// The tokens the server answers when the user signs in, if it answers any.
  AuthTokens? loginAnswer;

  /// The tokens the server answers when the token is refreshed, if it answers any.
  AuthTokens? refreshAnswer;

  /// Whether the login can build the request which refreshes the token.
  bool canBuildRefreshRequest;

  /// The number of times the response of the refresh was parsed.
  int parsedRefreshes = 0;

  /// Class constructor
  FakeRefreshJwtLogin({
    required super.serverRequester,
    this.loginAnswer,
    this.refreshAnswer,
    this.canBuildRefreshRequest = true,
  }) : super(logsHelper: FakeExternalLogger().buildHelper(category: "test"));

  /// Keeps [tokens] the way the answer of a server does.
  Future<void> keep(AuthTokens tokens) => updateTokenInfo(tokens);

  /// {@macro act_http_client_jwt_auth.AbsJwtLogin.getLoginRequestFromMemory}
  @override
  Future<RequestParam?> getLoginRequestFromMemory() async =>
      RequestParam(httpMethod: HttpMethods.post, relativeRoute: aLoginRoute);

  /// {@macro act_http_client_jwt_auth.AbsJwtLogin.parseLoginResponse}
  @override
  Future<AuthTokens?> parseLoginResponse(RequestResponse response) async => loginAnswer;

  /// {@macro act_http_client_jwt_auth.AbsRefreshJwtLogin.getRefreshRequest}
  @override
  Future<RequestParam?> getRefreshRequest() async => canBuildRefreshRequest
      ? RequestParam(httpMethod: HttpMethods.post, relativeRoute: aRefreshRoute)
      : null;

  /// {@macro act_http_client_jwt_auth.AbsRefreshJwtLogin.parseRefreshResponse}
  @override
  Future<AuthTokens?> parseRefreshResponse(RequestResponse response) async {
    parsedRefreshes++;

    return refreshAnswer;
  }
}

/// The login of an application which keeps the tokens of its user in a storage.
class FakeStoredJwtLogin extends AbsJwtLogin with MixinAuthStorageJwtLogin {
  /// The storage the tokens of the user are kept in.
  @override
  final MixinAuthStorageService? storageService;

  /// The tokens the server answers when the user signs in, if it answers any.
  AuthTokens? loginAnswer;

  /// Class constructor
  FakeStoredJwtLogin({required super.serverRequester, this.storageService, this.loginAnswer})
    : super(logsHelper: FakeExternalLogger().buildHelper(category: "test"));

  /// {@macro act_http_client_jwt_auth.AbsJwtLogin.getLoginRequestFromMemory}
  @override
  Future<RequestParam?> getLoginRequestFromMemory() async =>
      RequestParam(httpMethod: HttpMethods.post, relativeRoute: aLoginRoute);

  /// {@macro act_http_client_jwt_auth.AbsJwtLogin.parseLoginResponse}
  @override
  Future<AuthTokens?> parseLoginResponse(RequestResponse response) async => loginAnswer;
}

/// A request of the application which needs the user to be signed in.
RequestParam aRequest() => RequestParam(
  httpMethod: HttpMethods.get,
  relativeRoute: "/something",
  encoding: utf8,
);
