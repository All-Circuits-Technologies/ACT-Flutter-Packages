// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_oauth2.dart';

/// The configuration of the provider the tests sign their users in with.
const _conf = DefaultOAuth2Conf(
  clientId: "aClient",
  issuer: "https://a.provider",
  discoveryUrl: null,
  providerUrlConf: null,
  scopes: ["openid"],
  appAuthRedirectScheme: "com.example.app",
);

/// A token which is still valid.
final _validToken = AuthToken(raw: "a token", expiration: DateTime.now().toUtc().add(_anHour));

/// A token which has expired.
final _expiredToken = AuthToken(
  raw: "an old token",
  expiration: DateTime.now().toUtc().subtract(_anHour),
);

/// The time a token of the tests is valid for.
const _anHour = Duration(hours: 1);

/// The answer of a provider which signed the user in.
AuthorizationTokenResponse _authorized({
  String? accessToken = "a token",
  String? refreshToken = "a refresh token",
  String? idToken = "an id token",
}) => AuthorizationTokenResponse(
  accessToken,
  refreshToken,
  DateTime.now().toUtc().add(_anHour),
  idToken,
  "Bearer",
  const ["openid"],
  const {},
  const {},
);

/// The answer of a provider which handed a token over.
TokenResponse _tokens({String? accessToken = "another token", String? refreshToken}) =>
    TokenResponse(
      accessToken,
      refreshToken,
      DateTime.now().toUtc().add(_anHour),
      "an id token",
      "Bearer",
      const ["openid"],
      const {},
    );

void main() {
  late FakeGlobalManager globalManager;
  late FakeExternalLogger logs;
  late FakeAppAuth appAuth;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    logs = FakeExternalLogger();
    appAuth = FakeAppAuth();
  });

  tearDown(() => globalManager.reset());

  /// The service of an application which signs its users in through a provider.
  Future<FakeOAuth2Service> aService({FakeTokensStorage? storage}) async {
    final service = FakeOAuth2Service(conf: _conf);
    await service.initProvider(parentLogsHelper: logs.buildHelper(category: "auth"), appAuth: appAuth);
    addTearDown(service.disposeLifeCycle);

    if (storage != null) {
      await service.setStorageService(storage);
    }

    return service;
  }

  group("AbsOAuth2ProviderService.initProvider", () {
    test("logs under the category of the provider", () async {
      final service = await aService();

      expect(service.logCategories, ["auth", "aProvider"]);
    });

    test("starts with a user who is signed out", () async {
      final service = await aService();

      expect(service.authStatus, AuthStatus.signedOut);
      expect(await service.isUserSigned(), isFalse);
    });
  });

  group("AbsOAuth2ProviderService.setStorageService", () {
    test("takes the tokens which were kept for the user", () async {
      final storage = FakeTokensStorage(tokens: AuthTokens(accessToken: _validToken));

      final service = await aService(storage: storage);

      expect(await service.isUserSigned(), isTrue);
      expect((await service.getTokens())?.accessToken, _validToken);
    });

    test("keeps the tokens of the run over the ones which were kept", () async {
      final service = await aService();
      appAuth.authorizationAnswer = _authorized();
      await service.redirectToExternalUserSignIn();
      final storage = FakeTokensStorage(tokens: AuthTokens(accessToken: _expiredToken));

      await service.setStorageService(storage);

      expect(storage.tokens?.accessToken?.raw, "a token");
    });

    test("reads nothing from a storage which kept no token", () async {
      final service = await aService(storage: FakeTokensStorage());

      expect(await service.getTokens(), isNull);
    });

    test("forgets the storage of the tokens when it is given none", () async {
      final storage = FakeTokensStorage(tokens: AuthTokens(accessToken: _validToken));
      final service = await aService(storage: storage);

      await service.setStorageService(null);

      expect(service.storageService, isNull);
    });
  });

  group("AbsOAuth2ProviderService.redirectToExternalUserSignIn", () {
    test("signs the user in through the provider", () async {
      final service = await aService();
      appAuth.authorizationAnswer = _authorized();

      final result = await service.redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.done);
      expect(service.authStatus, AuthStatus.signedIn);
    });

    test("asks the provider for the client and the scopes of the application", () async {
      final service = await aService();
      appAuth.authorizationAnswer = _authorized();

      await service.redirectToExternalUserSignIn();

      final request = appAuth.authorizations.single;
      expect(request.clientId, "aClient");
      expect(request.issuer, "https://a.provider");
      expect(request.scopes, ["openid"]);
      expect(request.redirectUrl, "com.example.app:/oauthredirect");
    });

    test("keeps the tokens the provider handed over", () async {
      final storage = FakeTokensStorage();
      final service = await aService(storage: storage);
      appAuth.authorizationAnswer = _authorized();

      final result = await service.redirectToExternalUserSignIn();

      expect((result.extra! as AuthTokens).accessToken?.raw, "a token");
      expect(storage.tokens?.refreshToken?.raw, "a refresh token");
    });

    test("tells the application that the user is signed in", () async {
      final service = await aService();
      appAuth.authorizationAnswer = _authorized();

      final pushed = expectLater(service.authStatusStream, emits(AuthStatus.signedIn));
      await service.redirectToExternalUserSignIn();

      await pushed;
    });

    test("asks for a token when the provider only handed a refresh one over", () async {
      final service = await aService();
      appAuth.authorizationAnswer = _authorized(accessToken: null);
      appAuth.tokenAnswer = _tokens();

      final result = await service.redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.done);
      expect(appAuth.tokenRequests.single.refreshToken, "a refresh token");
      expect((await service.getTokens())?.accessToken?.raw, "another token");
    });

    test("gives up when the provider hands no token over at all", () async {
      final service = await aService();
      appAuth.authorizationAnswer = _authorized(accessToken: null, refreshToken: null);

      final result = await service.redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.genericError);
      expect(service.authStatus, AuthStatus.signedOut);
    });

    test("ends the session of a user who gave the sign in up", () async {
      final service = await aService();
      appAuth.authorizationError = FlutterAppAuthUserCancelledException(
        code: "authorize",
        message: "the user cancelled",
        platformErrorDetails: FlutterAppAuthPlatformErrorDetails(),
      );

      final result = await service.redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.sessionExpired);
    });

    test("gives up when the provider refused to sign the user in", () async {
      final service = await aService();
      appAuth.authorizationError = Exception("the provider is not there");

      final result = await service.redirectToExternalUserSignIn();

      expect(result.status, AuthSignInStatus.genericError);
    });
  });

  group("AbsOAuth2ProviderService.signOut", () {
    test("ends the session of the user at the provider", () async {
      final storage = FakeTokensStorage();
      final service = await aService(storage: storage);
      appAuth.authorizationAnswer = _authorized();
      await service.redirectToExternalUserSignIn();

      expect(await service.signOut(), isTrue);
      expect(appAuth.endSessions.single.idTokenHint, "an id token");
      expect(appAuth.endSessions.single.postLogoutRedirectUrl, "com.example.app:/");
    });

    test("forgets the tokens of the user", () async {
      final storage = FakeTokensStorage();
      final service = await aService(storage: storage);
      appAuth.authorizationAnswer = _authorized();
      await service.redirectToExternalUserSignIn();

      await service.signOut();

      expect(await service.getTokens(), isNull);
      expect(storage.tokens, isNull);
      expect(storage.clearCount, 1);
      expect(service.authStatus, AuthStatus.signedOut);
    });

    test("keeps the user signed in when the provider refused to end the session", () async {
      final service = await aService();
      appAuth.authorizationAnswer = _authorized();
      await service.redirectToExternalUserSignIn();
      appAuth.endSessionError = Exception("the provider is not there");

      expect(await service.signOut(), isFalse);
      expect(service.authStatus, AuthStatus.signedIn);
    });
  });

  group("AbsOAuth2ProviderService.isUserSigned", () {
    test("says that a user whose token is still valid is signed in", () async {
      final service = await aService(
        storage: FakeTokensStorage(tokens: AuthTokens(accessToken: _validToken)),
      );

      expect(await service.isUserSigned(), isTrue);
    });

    test("says that a user whose refresh token is still valid is signed in", () async {
      final service = await aService(
        storage: FakeTokensStorage(
          tokens: AuthTokens(accessToken: _expiredToken, refreshToken: _validToken),
        ),
      );

      expect(await service.isUserSigned(), isTrue);
    });

    test("signs out a user whose tokens have all expired", () async {
      final service = await aService(
        storage: FakeTokensStorage(
          tokens: AuthTokens(accessToken: _expiredToken, refreshToken: _expiredToken),
        ),
      );

      expect(await service.isUserSigned(), isFalse);
      expect(service.authStatus, AuthStatus.signedOut);
    });
  });

  group("AbsOAuth2ProviderService.getTokens", () {
    test("gives back the tokens of a user whose token is still valid", () async {
      final service = await aService(
        storage: FakeTokensStorage(tokens: AuthTokens(accessToken: _validToken)),
      );

      expect((await service.getTokens())?.accessToken, _validToken);
      expect(appAuth.tokenRequests, isEmpty);
    });

    test("asks the provider for a token with the refresh token of the user", () async {
      final storage = FakeTokensStorage(
        tokens: AuthTokens(accessToken: _expiredToken, refreshToken: _validToken),
      );
      final service = await aService(storage: storage);
      appAuth.tokenAnswer = _tokens();

      final tokens = await service.getTokens();

      expect(tokens?.accessToken?.raw, "another token");
      expect(appAuth.tokenRequests.single.refreshToken, "a token");
      expect(storage.tokens?.accessToken?.raw, "another token");
    });

    test("gives back nothing when the refresh token has expired too", () async {
      final service = await aService(
        storage: FakeTokensStorage(
          tokens: AuthTokens(accessToken: _expiredToken, refreshToken: _expiredToken),
        ),
      );

      expect(await service.getTokens(), isNull);
      expect(appAuth.tokenRequests, isEmpty);
    });

    test("gives back nothing when the provider refused to hand a token over", () async {
      final service = await aService(
        storage: FakeTokensStorage(
          tokens: AuthTokens(accessToken: _expiredToken, refreshToken: _validToken),
        ),
      );
      appAuth.tokenError = Exception("the provider is not there");

      expect(await service.getTokens(), isNull);
    });
  });

  group("AbsOAuth2ProviderService.signInUser", () {
    test("refuses to sign a user in with a password, which a provider owns", () async {
      final service = await aService();

      expect(
        () => service.signInUser(username: "a user", password: "a password"),
        throwsA(isA<Error>()),
      );
    });
  });
}
