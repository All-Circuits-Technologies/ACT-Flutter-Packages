// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes/fake_auth_storage_app.dart';

/// The tokens of a user who is signed in.
final _tokens = AuthTokens(
  accessToken: AuthToken(raw: "a token", expiration: DateTime.utc(2026, 8, 3)),
  refreshToken: const AuthToken(raw: "a refresh token"),
  idToken: "an id token",
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late FakeGlobalManager globalManager;
  late FakeAuthSecrets secrets;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() async {
    FakeAssets.stop();
    await globalManager.reset();
  });

  /// The storage of the tokens of an application which keeps them where the platform keeps its
  /// secrets.
  ///
  /// The user ids are only kept when [saveUserIds] says so, which is what the configuration of an
  /// application decides.
  Future<SecureLocalAuthStorage<FakeAuthConfig, FakeAuthSecrets>> aStorage({
    bool saveUserIds = true,
  }) async {
    FakeAssets.serve({
      "${configPath}default.yaml":
          "auth:\n  secrets:\n    localStorage:\n      saveUserIds: $saveUserIds",
    });

    final config = FakeAuthConfig();
    await config.initLifeCycle();
    addTearDown(config.disposeLifeCycle);

    final properties = FakeAuthProperties();
    await properties.initLifeCycle();

    secrets = FakeAuthSecrets(propertiesGetter: () => properties, confGetter: () => config);
    await secrets.initLifeCycle();

    globalManager.managers
      ..registerSingleton<FakeAuthConfig>(config)
      ..registerSingleton<FakeAuthSecrets>(secrets);

    return SecureLocalAuthStorage<FakeAuthConfig, FakeAuthSecrets>();
  }

  group("SecureLocalAuthStorage.storeTokens", () {
    test("keeps the tokens of the user between two runs", () async {
      final storage = await aStorage();

      expect(await storage.storeTokens(tokens: _tokens), isTrue);
      expect(await storage.loadTokens(), _tokens);
    });

    test("keeps the tokens where the secrets of the application are kept", () async {
      final storage = await aStorage();

      await storage.storeTokens(tokens: _tokens);

      expect(await secrets.authTokens.load(), _tokens);
    });

    test("replaces the tokens which were kept", () async {
      final storage = await aStorage();
      await storage.storeTokens(tokens: _tokens);

      const newTokens = AuthTokens(accessToken: AuthToken(raw: "another token"));
      await storage.storeTokens(tokens: newTokens);

      expect(await storage.loadTokens(), newTokens);
    });
  });

  group("SecureLocalAuthStorage.loadTokens", () {
    test("reads nothing for a user who was never signed in", () async {
      final storage = await aStorage();

      expect(await storage.loadTokens(), isNull);
    });
  });

  group("SecureLocalAuthStorage.clearTokens", () {
    test("forgets the tokens of the user", () async {
      final storage = await aStorage();
      await storage.storeTokens(tokens: _tokens);

      await storage.clearTokens();

      expect(await storage.loadTokens(), isNull);
    });
  });

  group("SecureLocalAuthStorage.isUserIdsStorageSupported", () {
    test("keeps the credentials of the user when the application allows it", () async {
      final storage = await aStorage();

      expect(await storage.isUserIdsStorageSupported(), isTrue);
    });

    test("keeps no credentials when the application does not allow it", () async {
      final storage = await aStorage(saveUserIds: false);

      expect(await storage.isUserIdsStorageSupported(), isFalse);
    });
  });

  group("SecureLocalAuthStorage.storeUserIds", () {
    test("keeps the credentials of the user between two runs", () async {
      final storage = await aStorage();

      expect(await storage.storeUserIds(username: "a user", password: "a password"), isTrue);
      expect(await storage.loadUserIds(), (username: "a user", password: "a password"));
    });

    test("refuses to keep the credentials the application does not allow it to", () async {
      final storage = await aStorage(saveUserIds: false);

      expect(await storage.storeUserIds(username: "a user", password: "a password"), isFalse);
      expect(await secrets.authIds.load(), isNull);
    });
  });

  group("SecureLocalAuthStorage.loadUserIds", () {
    test("reads nothing for a user whose credentials were never kept", () async {
      final storage = await aStorage();

      expect(await storage.loadUserIds(), isNull);
    });

    test("reads nothing when the application does not allow keeping credentials", () async {
      final storage = await aStorage(saveUserIds: false);
      await secrets.authIds.store(
        const AuthUserIds(username: "a user", password: "a password"),
      );

      expect(await storage.loadUserIds(), isNull);
    });
  });

  group("SecureLocalAuthStorage.clearUserIds", () {
    test("forgets the credentials of the user", () async {
      final storage = await aStorage();
      await storage.storeUserIds(username: "a user", password: "a password");

      await storage.clearUserIds();

      expect(await storage.loadUserIds(), isNull);
    });

    test("leaves the credentials alone when the application does not allow keeping them", () async {
      final storage = await aStorage(saveUserIds: false);
      await secrets.authIds.store(
        const AuthUserIds(username: "a user", password: "a password"),
      );

      await storage.clearUserIds();

      expect(await secrets.authIds.load(), isNotNull);
    });
  });
}
