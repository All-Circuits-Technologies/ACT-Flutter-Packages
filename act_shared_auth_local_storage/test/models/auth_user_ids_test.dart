// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FakeGlobalManager.install);

  group("AuthUserIds.toJson", () {
    test("writes the credentials of a user, and reads them back", () {
      const userIds = AuthUserIds(username: "a user", password: "a password");

      expect(AuthUserIds.fromJson(userIds.toJson()), userIds);
    });
  });

  group("AuthUserIds.fromJson", () {
    test("reads nothing from a value which carries no user name", () {
      expect(AuthUserIds.fromJson(const {"password": "a password"}), isNull);
    });

    test("reads nothing from a value which carries no password", () {
      expect(AuthUserIds.fromJson(const {"username": "a user"}), isNull);
    });

    test("reads nothing from a value whose credentials are not written as text", () {
      expect(AuthUserIds.fromJson(const {"username": 42, "password": "a password"}), isNull);
    });
  });

  group("AuthUserIds", () {
    test("is the same credentials as another one which carries the same", () {
      expect(
        const AuthUserIds(username: "a user", password: "a password"),
        const AuthUserIds(username: "a user", password: "a password"),
      );
    });

    test("is another credentials as soon as the password differs", () {
      expect(
        const AuthUserIds(username: "a user", password: "a password"),
        isNot(const AuthUserIds(username: "a user", password: "another password")),
      );
    });
  });
}
