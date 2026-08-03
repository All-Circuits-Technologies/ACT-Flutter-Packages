@TestOn('browser')
// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1
library;

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:act_web_local_storage_manager/src/services/cookie_session_singleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart';

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  /// The number of keys the tests have used, which is what keeps them apart.
  var keyCount = 0;

  /// A key no other test of this file writes to.
  ///
  /// The cookies of a page are shared by the whole file, so a test which reads the key of another
  /// one would read what that other one wrote.
  String aKey() => "aKey${keyCount++}";

  group("CookieSessionSingleton.instance", () {
    // The singleton is never released, so only the first test of this file sees it missing
    test("refuses to answer before the application created it", () {
      expect(
        () => CookieSessionSingleton.instance,
        throwsA(isA<ActSingletonNotCreatedError<CookieSessionSingleton>>()),
      );
    });
  });

  group("CookieSessionSingleton.createInstance", () {
    test("gives back the singleton which already exists rather than another one", () {
      final first = CookieSessionSingleton.createInstance();

      expect(CookieSessionSingleton.createInstance(), same(first));
    });
  });

  group("CookieSessionSingleton", () {
    late CookieSessionSingleton cookies;

    setUp(() => cookies = CookieSessionSingleton.createInstance());

    test("reads back the text it wrote", () async {
      final key = aKey();

      await cookies.store<String>(key: key, value: "a value");

      expect(await cookies.load<String>(key: key), "a value");
    });

    test("reads back the number it wrote", () async {
      final key = aKey();

      await cookies.store<int>(key: key, value: 42);

      expect(await cookies.load<int>(key: key), 42);
    });

    test("reads back the boolean it wrote", () async {
      final key = aKey();

      await cookies.store<bool>(key: key, value: true);

      expect(await cookies.load<bool>(key: key), isTrue);
    });

    test("reads nothing under a key nobody wrote to", () async {
      expect(await cookies.load<String>(key: aKey()), isNull);
    });

    test("reads nothing under a key it deleted", () async {
      final key = aKey();
      await cookies.store<String>(key: key, value: "a value");

      await cookies.delete(key: key);

      expect(await cookies.load<String>(key: key), isNull);
    });

    test("deletes the value when the application writes nothing under the key", () async {
      final key = aKey();
      await cookies.store<String>(key: key, value: "a value");

      await cookies.store<String>(key: key, value: null);

      expect(await cookies.load<String>(key: key), isNull);
    });

    test("tells the values of two keys apart", () async {
      final first = aKey();
      final second = aKey();

      await cookies.store<String>(key: first, value: "the first");
      await cookies.store<String>(key: second, value: "the second");

      expect(await cookies.load<String>(key: first), "the first");
      expect(await cookies.load<String>(key: second), "the second");
    });

    test("reads back a value which holds the separator of a cookie", () async {
      final key = aKey();

      await cookies.store<String>(key: key, value: "YWJjZA==");

      expect(await cookies.load<String>(key: key), "YWJjZA==");
    });

    test("refuses a value of a type the cookies cannot hold", () async {
      expect(
        () => cookies.store<Duration>(key: aKey(), value: const Duration(seconds: 1)),
        throwsA(isA<ActUnsupportedTypeError<Duration>>()),
      );
    });
  });

  group("CookieSessionSingleton.deleteAll", () {
    test("keeps the cookies of the page, which are not all its own", () async {
      final cookies = CookieSessionSingleton.createInstance();
      final key = aKey();
      await cookies.store<String>(key: key, value: "a value");

      await cookies.deleteAll();

      expect(await cookies.load<String>(key: key), "a value");
      expect(document.cookie, contains(key));
    });

    test("warns the application which asked for it", () async {
      final cookies = CookieSessionSingleton.createInstance();

      await cookies.deleteAll();

      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
    });
  });
}
