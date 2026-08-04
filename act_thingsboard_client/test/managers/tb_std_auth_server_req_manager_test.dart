// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../fakes/fake_thingsboard.dart';

void main() {
  late FakeGlobalManager globalManager;
  late FakeNoAuthReqManager noAuthManager;
  late FakeTbAuthManager authManager;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    noAuthManager = FakeNoAuthReqManager();
    authManager = FakeTbAuthManager();
    await authManager.initLifeCycle();
    globalGetIt().registerSingleton<TbNoAuthServerReqManager>(noAuthManager);

    when(
      () => noAuthManager.client.setUserFromJwtToken(any(), any(), any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authManager.service.close();
    await globalManager.reset();
  });

  /// The tokens of a user who is signed in.
  const tokens = AuthTokens(
    accessToken: AuthToken(raw: "a token"),
    refreshToken: AuthToken(raw: "a refresh token"),
  );

  /// Builds the manager which reaches the server as the user, and initializes it.
  Future<TbStdAuthServerReqManager> aManager({AuthTokens? userTokens = tokens}) async {
    authManager.service.tokens = userTokens;

    final manager = TbStdAuthServerReqManager(authGetter: () => authManager);
    await manager.initLifeCycle();

    return manager;
  }

  group("TbStdAuthServerReqBuilder", () {
    test("depends on the logger, on the manager without a user and on the authentication", () {
      final builder = TbStdAuthServerReqBuilder<FakeTbAuthManager>();

      expect(builder.dependsOn(), [
        LoggerManager,
        TbNoAuthServerReqManager,
        FakeTbAuthManager,
      ]);
    });
  });

  group("TbStdAuthServerReqManager.initLifeCycle", () {
    test("reaches the server through the client of the manager without a user", () async {
      final manager = await aManager();

      expect(manager.tbClient, same(noAuthManager.client));
    });

    test("hands over a service of the devices of the server", () async {
      final manager = await aManager();

      expect(manager.devicesService, isNotNull);
    });
  });

  group("TbStdAuthServerReqManager.request", () {
    test("answers what the server answered", () async {
      final manager = await aManager();

      final response = await manager.request((tbClient) async => "an answer");

      expect(response.status, RequestStatus.success);
      expect(response.requestResponse, "an answer");
    });

    test("hands the tokens of the user to the client before it requests anything", () async {
      final manager = await aManager();

      await manager.request((tbClient) async => "an answer");

      verify(
        () => noAuthManager.client.setUserFromJwtToken("a token", "a refresh token", null),
      ).called(1);
    });

    test("answers a login error when the user has no token", () async {
      final manager = await aManager(userTokens: null);

      final response = await manager.request((tbClient) async => "an answer");

      expect(response.status, RequestStatus.loginError);
      expect(noAuthManager.requestCount, 0);
    });

    test("asks the tokens again and requests once more on a login error", () async {
      final manager = await aManager();
      noAuthManager.answers.add(RequestStatus.loginError);

      final response = await manager.request((tbClient) async => "an answer");

      expect(response.status, RequestStatus.success);
      expect(noAuthManager.requestCount, 2);
      expect(authManager.service.tokensCalls, 2);
    });

    test("gives up when the second request fails on a login error too", () async {
      final manager = await aManager();
      noAuthManager.answers.addAll([RequestStatus.loginError, RequestStatus.loginError]);

      final response = await manager.request((tbClient) async => "an answer");

      expect(response.status, RequestStatus.loginError);
      expect(noAuthManager.requestCount, 2);
    });

    test("requests once more only for a login error", () async {
      final manager = await aManager();
      noAuthManager.answers.add(RequestStatus.globalError);

      final response = await manager.request((tbClient) async => "an answer");

      expect(response.status, RequestStatus.globalError);
      expect(noAuthManager.requestCount, 1);
    });

    test("answers a login error when the user lost the tokens in between", () async {
      final manager = await aManager();
      noAuthManager.answers.add(RequestStatus.loginError);
      authManager.service.tokens = null;

      final response = await manager.request((tbClient) async => "an answer");

      expect(response.status, RequestStatus.loginError);
      expect(noAuthManager.requestCount, 0);
    });
  });
}
