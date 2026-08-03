@TestOn('browser')
// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
library;

import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_web_local_storage_manager/act_web_local_storage_manager.dart';
import 'package:act_web_local_storage_manager/src/services/cookie_session_singleton.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FakeGlobalManager.install();
    CookieSessionSingleton.createInstance();
  });

  group("CookieSessionItem", () {
    test("keeps the value of its key for as long as the session lasts", () async {
      const item = CookieSessionItem<String>("aText");

      await item.store("a value");

      expect(await item.load(), "a value");
    });

    test("keeps a number as well as a text", () async {
      const item = CookieSessionItem<int>("aNumber");

      await item.store(42);

      expect(await item.load(), 42);
    });

    test("reads nothing before anything was written under its key", () async {
      expect(await const CookieSessionItem<String>("nothingHere").load(), isNull);
    });

    test("reads nothing once it was deleted", () async {
      const item = CookieSessionItem<String>("aDeletedText");
      await item.store("a value");

      await item.delete();

      expect(await item.load(), isNull);
    });

    test("reads what another item of the same key wrote", () async {
      const written = CookieSessionItem<String>("aSharedKey");
      const read = CookieSessionItem<String>("aSharedKey");
      await written.store("a value");

      expect(await read.load(), "a value");
    });
  });
}
