// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth.dart';

void main() {
  late BareAuthStorageService storage;

  setUp(() => storage = BareAuthStorageService());

  group("MixinAuthStorageService.isUserIdsStorageSupported", () {
    test("keeps no identifier of the user unless the storage says it does", () async {
      expect(await storage.isUserIdsStorageSupported(), isFalse);
    });

    test("keeps the identifiers of the user when the storage says it does", () async {
      expect(await FakeAuthStorageService().isUserIdsStorageSupported(), isTrue);
    });
  });

  group("MixinAuthStorageService", () {
    // The assertions are enabled when the tests are run, so the trap of the mixin fires the
    // assertion it guards the release behaviour with.
    test("crashes when the identifiers are stored in a storage which keeps none", () {
      expect(
        () => storage.storeUserIds(username: "a user", password: "a password"),
        throwsAssertionError,
      );
    });

    test("crashes when the identifiers are read from a storage which keeps none", () {
      expect(storage.loadUserIds, throwsAssertionError);
    });

    test("crashes when the identifiers are cleared from a storage which keeps none", () {
      expect(storage.clearUserIds, throwsAssertionError);
    });
  });
}
