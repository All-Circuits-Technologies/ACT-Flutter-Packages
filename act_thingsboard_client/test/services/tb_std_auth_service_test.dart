// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

import '../fakes/fake_thingsboard.dart';

void main() {
  late FakeGlobalManager globalManager;
  late FakeNoAuthReqManager noAuthManager;
  late FakeTbAuthStorageService storage;

  setUpAll(() => registerFallbackValue(LoginRequest("a user", "a password")));

  setUp(() {
    globalManager = FakeGlobalManager.install();
    noAuthManager = FakeNoAuthReqManager();
    storage = FakeTbAuthStorageService();
    globalGetIt().registerSingleton<TbNoAuthServerReqManager>(noAuthManager);
  });

  tearDown(() => globalManager.reset());

  /// Has the client answer that it holds [token] and [refreshToken] for the user.
  void clientHolds({String? token, String? refreshToken}) {
    when(noAuthManager.client.getJwtToken).thenReturn(token);
    when(noAuthManager.client.getRefreshToken).thenReturn(refreshToken);
  }

  /// Has the server answer a token to whoever signs in or refreshes a token.
  ///
  /// The client then holds the tokens the server answered, the way a real client does.
  void serverAnswers({String? token, String? refreshToken}) {
    final answered = token ?? aJwtToken();

    when(() => noAuthManager.client.login(any())).thenAnswer((_) async {
      clientHolds(token: answered, refreshToken: refreshToken);

      return LoginResponse(answered, refreshToken);
    });
    when(
      () => noAuthManager.client.refreshJwtToken(refreshToken: any(named: "refreshToken")),
    ).thenAnswer((_) async => clientHolds(token: answered, refreshToken: refreshToken));
    when(noAuthManager.client.logout).thenAnswer((_) async => clientHolds());
  }

  /// Builds the service which signs a user in on the server, and initializes it.
  ///
  /// The service keeps what it knows of the user in the storage of the tests, unless
  /// [withoutStorage] says that the application keeps nothing.
  Future<TbStdAuthService> aService({bool withoutStorage = false}) async {
    final service = TbStdAuthService();
    if (!withoutStorage) {
      await service.setStorageService(storage);
    }
    await service.initLifeCycle();

    return service;
  }

  group("TbStdAuthService.initLifeCycle", () {
    test("leaves the user signed out when the application keeps nothing", () async {
      final service = await aService(withoutStorage: true);

      expect(service.authStatus, AuthStatus.signedOut);
      expect(noAuthManager.requestCount, 0);
    });

    test("signs the user in again from the token the application kept", () async {
      final token = aJwtToken();
      storage.storedTokens = AuthTokens(accessToken: AuthToken(raw: token));
      clientHolds(token: token);

      final service = await aService();

      expect(service.authStatus, AuthStatus.signedIn);
    });

    test("asks the server for a new token when the one which was kept expired", () async {
      storage.storedTokens = AuthTokens(
        accessToken: AuthToken(raw: "an old token", expiration: DateTime.utc(2020)),
        refreshToken: const AuthToken(raw: "a refresh token"),
      );
      serverAnswers(token: aJwtToken());

      final service = await aService();

      verify(
        () => noAuthManager.client.refreshJwtToken(refreshToken: "a refresh token"),
      ).called(1);
      expect(service.authStatus, AuthStatus.signedIn);
    });

    test("signs the user in from the identifiers which were kept", () async {
      storage.storedTokens = null;
      storage.storedUserIds = (username: "a user", password: "a password");
      serverAnswers();

      final service = await aService();

      verify(() => noAuthManager.client.login(any())).called(1);
      expect(service.authStatus, AuthStatus.signedIn);
    });

    test("says that the session expired when nothing was kept of the user", () async {
      clientHolds();

      final service = await aService();

      expect(service.authStatus, AuthStatus.sessionExpired);
    });

    test("says that the session expired when the storage keeps no identifiers", () async {
      storage = FakeTbAuthStorageService(userIdsSupported: false);
      clientHolds();

      final service = await aService();

      expect(service.authStatus, AuthStatus.sessionExpired);
    });

    test("forgets the identifiers the server refuses", () async {
      storage.storedUserIds = (username: "a user", password: "a password");
      serverAnswers();
      noAuthManager.answers.add(RequestStatus.loginError);

      final service = await aService();

      expect(storage.storedUserIds, isNull);
      expect(service.authStatus, AuthStatus.sessionExpired);
    });
  });

  group("TbStdAuthService.signInUser", () {
    test("signs the user in on the server", () async {
      final service = await aService(withoutStorage: true);
      serverAnswers();

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.done);
      expect(service.authStatus, AuthStatus.signedIn);
    });

    test("keeps the identifiers of the user when the application can keep them", () async {
      final service = await aService();
      serverAnswers();

      await service.signInUser(username: "a user", password: "a password");

      expect(storage.storedUserIds, (username: "a user", password: "a password"));
    });

    test("keeps no identifier when the application cannot keep them", () async {
      storage = FakeTbAuthStorageService(userIdsSupported: false);
      final service = await aService();
      serverAnswers();

      await service.signInUser(username: "a user", password: "a password");

      expect(storage.storedUserIds, isNull);
    });

    test("says that the identifiers are wrong when the server refuses them", () async {
      final service = await aService(withoutStorage: true);
      serverAnswers();
      noAuthManager.answers.add(RequestStatus.loginError);

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, AuthSignInStatus.sessionExpired);
      expect(service.authStatus, AuthStatus.sessionExpired);
    });

    test("leaves the user as it was when the server cannot be reached", () async {
      final service = await aService(withoutStorage: true);
      serverAnswers();
      noAuthManager.answers.add(RequestStatus.globalError);

      final result = await service.signInUser(username: "a user", password: "a password");

      expect(result.status, isNot(AuthSignInStatus.done));
      expect(service.authStatus, AuthStatus.signedOut);
    });
  });

  group("TbStdAuthService.signOut", () {
    test("signs the user out of the server", () async {
      final service = await aService(withoutStorage: true);
      serverAnswers();
      await service.signInUser(username: "a user", password: "a password");

      final result = await service.signOut();

      expect(result, isTrue);
      expect(service.authStatus, AuthStatus.signedOut);
      verify(noAuthManager.client.logout).called(1);
    });

    test("forgets the identifiers the application kept", () async {
      final service = await aService();
      serverAnswers();
      await service.signInUser(username: "a user", password: "a password");

      await service.signOut();

      expect(storage.storedUserIds, isNull);
    });
  });

  group("TbStdAuthService.isUserSigned", () {
    test("says that a user who signed in is signed in", () async {
      final service = await aService(withoutStorage: true);
      serverAnswers();
      await service.signInUser(username: "a user", password: "a password");

      expect(await service.isUserSigned(), isTrue);
    });

    test("says that a user who never signed in is not signed in", () async {
      final service = await aService(withoutStorage: true);

      expect(await service.isUserSigned(), isFalse);
    });
  });

  group("TbStdAuthService.getTokens", () {
    test("answers the tokens the client holds", () async {
      final token = aJwtToken();
      final service = await aService(withoutStorage: true);
      clientHolds(token: token);

      final tokens = await service.getTokens();

      expect(tokens?.accessToken?.raw, token);
    });

    test("answers nothing when the client holds no token", () async {
      final service = await aService(withoutStorage: true);
      clientHolds();

      expect(await service.getTokens(), isNull);
    });

    test("answers nothing when the token the client holds is not a JWT", () async {
      final service = await aService(withoutStorage: true);
      clientHolds(token: "not a token");

      expect(await service.getTokens(), isNull);
    });
  });

  group("TbStdAuthService.authStatusStream", () {
    test("tells the application when the user signs in", () async {
      final service = await aService(withoutStorage: true);
      serverAnswers();
      final statuses = <AuthStatus>[];
      service.authStatusStream.listen(statuses.add);

      await service.signInUser(username: "a user", password: "a password");
      await pumpEventQueue();

      expect(statuses, [AuthStatus.signedIn]);
    });

    test("says nothing when the status of the user did not change", () async {
      final service = await aService(withoutStorage: true);
      serverAnswers();
      await service.signInUser(username: "a user", password: "a password");
      final statuses = <AuthStatus>[];
      service.authStatusStream.listen(statuses.add);

      await service.signInUser(username: "a user", password: "a password");
      await pumpEventQueue();

      expect(statuses, isEmpty);
    });

    test("tells the application when the user signs out", () async {
      final service = await aService(withoutStorage: true);
      serverAnswers();
      await service.signInUser(username: "a user", password: "a password");
      final statuses = <AuthStatus>[];
      service.authStatusStream.listen(statuses.add);

      await service.signOut();
      await pumpEventQueue();

      expect(statuses, [AuthStatus.signedOut]);
    });
  });

  group("TbStdAuthService.storageService", () {
    test("hands over the storage the application gave it", () async {
      final service = await aService();

      expect(service.storageService, same(storage));
    });

    test("hands over nothing when the application gave it none", () async {
      final service = await aService(withoutStorage: true);

      expect(service.storageService, isNull);
    });
  });
}
