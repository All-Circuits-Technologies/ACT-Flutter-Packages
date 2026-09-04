// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_http_client_manager/act_http_client_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_thingsboard_client/act_thingsboard_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

import '../fakes/fake_thingsboard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeTbAuthStorageService storage;
  FakeTbConfigManager? config;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    storage = FakeTbAuthStorageService();
  });

  tearDown(() async {
    FakeAssets.stop();
    await config?.disposeLifeCycle();
    config = null;
    await globalManager.reset();
  });

  /// Builds the manager which reaches the server named by [conf], and initializes it.
  ///
  /// The manager keeps the tokens of the user in the storage of the tests, unless
  /// [withoutStorage] says that the application keeps none.
  Future<TbNoAuthServerReqManager> aManager({
    String conf = aServerConf,
    bool withoutStorage = false,
  }) async {
    config = await FakeTbConfigManager.withContent(conf);

    final manager = TbNoAuthServerReqManager(
      storageServiceGetter: withoutStorage ? null : () => storage,
      confGetter: () => config!,
    );
    await manager.initLifeCycle();

    return manager;
  }

  group("TbNoAuthServerReqBuilder", () {
    test("depends on the configuration of the application and on the logger", () {
      final builder = TbNoAuthServerReqBuilder<FakeTbConfigManager, AbsAuthManager>();

      expect(builder.dependsOn(), [FakeTbConfigManager, LoggerManager]);
    });
  });

  group("TbNoAuthServerReqManager.initLifeCycle", () {
    test("gives up when the configuration names no server", () async {
      config = await FakeTbConfigManager.withContent("thingsboard:\n  port: 8080");

      final manager = TbNoAuthServerReqManager(
        storageServiceGetter: () => storage,
        confGetter: () => config!,
      );

      expect(manager.initLifeCycle, throwsA(isA<ActMissingConfigException>()));
    });

    test("reaches a server which is named without a port", () async {
      final manager = await aManager(conf: "thingsboard:\n  host: a.server");

      expect(manager.tbClient, isNotNull);
    });

    test("reaches a server which is named without TLS", () async {
      final manager = await aManager(
        conf: "thingsboard:\n  host: a.server\n  enableTls: false",
      );

      expect(manager.tbClient, isNotNull);
    });

    test("hands the client the tokens the application keeps", () async {
      final manager = await aManager();

      await manager.tbClient.setUserFromJwtToken(aJwtToken(), aJwtToken(), null);

      expect(storage.storedTokens?.accessToken?.raw, manager.tbClient.getJwtToken());
      expect(storage.storedTokens?.refreshToken?.raw, manager.tbClient.getRefreshToken());
    });

    test("has the application forget its tokens when the client forgets the user", () async {
      storage.storedTokens = AuthTokens(
        accessToken: AuthToken(raw: aJwtToken()),
        refreshToken: AuthToken(raw: aJwtToken()),
      );
      final manager = await aManager();

      await manager.tbClient.setUserFromJwtToken(null, null, null);

      expect(storage.storedTokens?.accessToken, isNull);
      expect(storage.storedTokens?.refreshToken, isNull);
    });

    test("keeps no token when the application keeps none", () async {
      final manager = await aManager(withoutStorage: true);

      await manager.tbClient.setUserFromJwtToken(aJwtToken(), null, null);

      expect(storage.calls, isEmpty);
    });
  });

  group("TbNoAuthServerReqManager.request", () {
    test("answers what the server answered", () async {
      final manager = await aManager();

      final response = await manager.request((tbClient) async => "an answer");

      expect(response.status, RequestStatus.success);
      expect(response.requestResponse, "an answer");
    });

    test("hands the client of the manager over to the request", () async {
      final manager = await aManager();

      final response = await manager.request((tbClient) async => tbClient);

      expect(response.requestResponse, same(manager.tbClient));
    });

    test("answers a login error when the token of the user expired", () async {
      final manager = await aManager();

      final response = await manager.request<String>(
        (tbClient) async =>
            throw ThingsboardError(errorCode: ThingsBoardErrorCode.jwtTokenExpired),
      );

      expect(response.status, RequestStatus.loginError);
    });

    test("answers a login error when the server refuses to authenticate the user", () async {
      final manager = await aManager();

      final response = await manager.request<String>(
        (tbClient) async =>
            throw ThingsboardError(errorCode: ThingsBoardErrorCode.authentication),
      );

      expect(response.status, RequestStatus.loginError);
    });

    test("answers a global error when the server raises a generic error", () async {
      final manager = await aManager();

      final response = await manager.request<String>(
        (tbClient) async => throw ThingsboardError(
          errorCode: ThingsBoardErrorCode.general,
          message: "an error",
        ),
      );

      expect(response.status, RequestStatus.globalError);
    });

    test("answers a global error when the server refuses the request", () async {
      final manager = await aManager();

      final response = await manager.request<String>(
        (tbClient) async => throw ThingsboardError(errorCode: ThingsBoardErrorCode.itemNotFound),
      );

      expect(response.status, RequestStatus.globalError);
    });

    test("answers a global error when the request raises anything else", () async {
      final manager = await aManager();

      final response = await manager.request<String>(
        (tbClient) async => throw const FormatException("not an answer of the server"),
      );

      expect(response.status, RequestStatus.globalError);
      expect(response.requestResponse, isNull);
    });
  });
}
