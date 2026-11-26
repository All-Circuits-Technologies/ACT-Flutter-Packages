// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';
import 'package:act_test_utility/act_test_utility.dart';
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
  late FakeAuthProperties properties;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() => globalManager.reset());

  /// The storage of the tokens of an application which keeps them in clear text.
  Future<NotSecureLocalAuthStorage<FakeAuthProperties>> aStorage() async {
    properties = FakeAuthProperties();
    await properties.initLifeCycle();
    await properties.deleteAll();

    globalManager.managers.registerSingleton<FakeAuthProperties>(properties);

    return NotSecureLocalAuthStorage<FakeAuthProperties>();
  }

  group("NotSecureLocalAuthStorage", () {
    test("keeps no credentials, whatever the application asks for", () async {
      final storage = await aStorage();

      expect(await storage.isUserIdsStorageSupported(), isFalse);
    });
  });

  group("NotSecureLocalAuthStorage.storeTokens", () {
    test("keeps the tokens of the user between two runs", () async {
      final storage = await aStorage();

      expect(await storage.storeTokens(tokens: _tokens), isTrue);
      expect(await storage.loadTokens(), _tokens);
    });

    test("keeps the tokens among the properties of the application", () async {
      final storage = await aStorage();

      await storage.storeTokens(tokens: _tokens);

      expect(await properties.authTokens.load(), _tokens);
    });

    test("replaces the tokens which were kept", () async {
      final storage = await aStorage();
      await storage.storeTokens(tokens: _tokens);

      const newTokens = AuthTokens(accessToken: AuthToken(raw: "another token"));
      await storage.storeTokens(tokens: newTokens);

      expect(await storage.loadTokens(), newTokens);
    });
  });

  group("NotSecureLocalAuthStorage.loadTokens", () {
    test("reads nothing for a user who was never signed in", () async {
      final storage = await aStorage();

      expect(await storage.loadTokens(), isNull);
    });
  });

  group("NotSecureLocalAuthStorage.clearTokens", () {
    test("forgets the tokens of the user", () async {
      final storage = await aStorage();
      await storage.storeTokens(tokens: _tokens);

      await storage.clearTokens();

      expect(await storage.loadTokens(), isNull);
    });
  });
}
