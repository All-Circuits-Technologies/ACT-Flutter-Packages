// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';
import 'package:act_shared_auth_local_storage/src/utilities/memory_storage_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeLogger logs;

  setUp(() {
    logs = FakeLogger();
    FakeGlobalManager.install(logger: logs);
  });

  group("MemoryStorageUtility.convertAuthTokensForStorage", () {
    test("writes the tokens of a user as one value the storage holds", () {
      final tokens = AuthTokens(
        accessToken: AuthToken(raw: "a token", expiration: DateTime.utc(2026, 8, 3)),
        refreshToken: const AuthToken(raw: "a refresh token"),
        idToken: "an id token",
      );

      final stored = MemoryStorageUtility.convertAuthTokensForStorage(tokens);

      expect(MemoryStorageUtility.convertAuthTokensFromStorage(stored), tokens);
    });

    test("writes the tokens of a user who has none", () {
      const tokens = AuthTokens();

      final stored = MemoryStorageUtility.convertAuthTokensForStorage(tokens);

      expect(MemoryStorageUtility.convertAuthTokensFromStorage(stored), tokens);
    });
  });

  group("MemoryStorageUtility.convertAuthTokensFromStorage", () {
    test("reads nothing from a storage which holds nothing", () {
      expect(MemoryStorageUtility.convertAuthTokensFromStorage(null), isNull);
    });

    test("reads nothing from a value which is not written as a json object", () {
      expect(MemoryStorageUtility.convertAuthTokensFromStorage("not json"), isNull);
      expect(logs.recordsAtLevel(LogsLevel.warn), isNotEmpty);
    });

    test("reads nothing from a value which is a json array", () {
      expect(MemoryStorageUtility.convertAuthTokensFromStorage("[]"), isNull);
      expect(logs.recordsAtLevel(LogsLevel.warn), isNotEmpty);
    });
  });

  group("MemoryStorageUtility.convertAuthUserIdsForStorage", () {
    test("writes the credentials of a user as one value the storage holds", () {
      const userIds = AuthUserIds(username: "a user", password: "a password");

      final stored = MemoryStorageUtility.convertAuthUserIdsForStorage(userIds);

      expect(MemoryStorageUtility.convertAuthUserIdsFromStorage(stored), userIds);
    });
  });

  group("MemoryStorageUtility.convertAuthUserIdsFromStorage", () {
    test("reads nothing from a storage which holds nothing", () {
      expect(MemoryStorageUtility.convertAuthUserIdsFromStorage(null), isNull);
    });

    test("reads nothing from a value which carries no user name", () {
      expect(MemoryStorageUtility.convertAuthUserIdsFromStorage('{"password": "a"}'), isNull);
    });

    test("reads nothing from a value which is not written as a json object", () {
      expect(MemoryStorageUtility.convertAuthUserIdsFromStorage("not json"), isNull);
    });
  });
}
