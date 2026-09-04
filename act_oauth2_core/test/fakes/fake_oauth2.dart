// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

/// The identity providers an application under test offers.
enum FakeProviders {
  /// The provider the application signs its users in with.
  identity,

  /// Another provider, which does not speak OAuth 2.
  legacy,
}

/// The identity provider of the tests, which answers what the test lined up.
///
/// The library which speaks to a provider opens a browser and talks to a server: this class is
/// what stands in for it, and it records the requests it was sent so that a test can read what the
/// service asked for.
class FakeAppAuth implements FlutterAppAuth {
  /// The authorizations the service asked for, in the order it asked.
  final List<AuthorizationTokenRequest> authorizations = [];

  /// The tokens the service asked for, in the order it asked.
  final List<TokenRequest> tokenRequests = [];

  /// The sessions the service asked to end, in the order it asked.
  final List<EndSessionRequest> endSessions = [];

  /// The answer of the provider to an authorization, if it answers one.
  AuthorizationTokenResponse? authorizationAnswer;

  /// The answer of the provider to a token request, if it answers one.
  TokenResponse? tokenAnswer;

  /// The error the provider raises instead of authorizing, if it raises one.
  Exception? authorizationError;

  /// The error the provider raises instead of ending the session, if it raises one.
  Exception? endSessionError;

  /// The error the provider raises instead of answering a token, if it raises one.
  Exception? tokenError;

  /// Class constructor
  FakeAppAuth();

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    authorizations.add(request);

    if (authorizationError != null) {
      throw authorizationError!;
    }

    return authorizationAnswer!;
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    tokenRequests.add(request);

    if (tokenError != null) {
      throw tokenError!;
    }

    return tokenAnswer!;
  }

  @override
  Future<EndSessionResponse> endSession(EndSessionRequest request) async {
    endSessions.add(request);

    if (endSessionError != null) {
      throw endSessionError!;
    }

    return EndSessionResponse("a state");
  }

  @override
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) async =>
      throw UnimplementedError("The service under test authorizes and exchanges in one call");
}

/// The provider service of an application, over the configuration the test gives it.
class FakeOAuth2Service extends AbsOAuth2ProviderService {
  /// The configuration of the provider the service signs the users in with.
  final DefaultOAuth2Conf conf;

  /// Class constructor
  FakeOAuth2Service({required this.conf}) : super(logsCategory: "aProvider");

  /// The categories the service logs under, which a test reads to know it built its own logger.
  List<String> get logCategories => logsHelper.categories;

  /// {@macro act_oauth2_google.AbsOAuth2ProviderService.getDefaultOAuth2Conf}
  @override
  Future<DefaultOAuth2Conf> getDefaultOAuth2Conf() async => conf;
}

/// The storage of the tokens of an application, in memory.
class FakeTokensStorage with MixinAuthStorageService {
  /// The tokens the storage holds.
  AuthTokens? tokens;

  /// The number of times the tokens were cleared.
  int clearCount = 0;

  /// Class constructor
  FakeTokensStorage({this.tokens});

  /// {@macro act_shared_auth.MixinAuthStorageService.storeTokens}
  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    this.tokens = tokens;

    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadTokens}
  @override
  Future<AuthTokens?> loadTokens() async => tokens;

  /// {@macro act_shared_auth.MixinAuthStorageService.clearTokens}
  @override
  Future<void> clearTokens() async {
    clearCount++;
    tokens = null;
  }
}

/// An authentication service which is not an OAuth 2 one.
class FakeOtherService with MixinAuthService {
  /// Whether the service signed the user out.
  bool signedOut = false;

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus => AuthStatus.signedOut;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => const Stream<AuthStatus>.empty();

  /// {@macro act_shared_auth.MixinAuthService.setStorageService}
  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async {}

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  @override
  Future<AuthSignInResult> signInUser({
    required String username,
    required String password,
  }) async => const AuthSignInResult(status: AuthSignInStatus.done);

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() async {
    signedOut = true;

    return true;
  }

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() async => false;
}
