// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_local_storage_manager/src/services/properties_singleton.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PropertiesSingleton properties;

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  setUp(() async {
    FakeGlobalManager.install();
    properties = PropertiesSingleton.createInstance();
    await properties.deleteAll();
  });

  group("PropertiesSingleton.createInstance", () {
    test("returns the same instance every time", () {
      expect(PropertiesSingleton.createInstance(), same(properties));
    });

    test("is the instance the items reach", () {
      expect(PropertiesSingleton.instance, same(properties));
    });
  });

  group("PropertiesSingleton.store", () {
    test("keeps a boolean", () async {
      await properties.store<bool>(key: "aKey", value: true);

      expect(await properties.load<bool>(key: "aKey"), isTrue);
    });

    test("keeps an integer", () async {
      await properties.store<int>(key: "aKey", value: 42);

      expect(await properties.load<int>(key: "aKey"), 42);
    });

    test("keeps a double", () async {
      await properties.store<double>(key: "aKey", value: 4.2);

      expect(await properties.load<double>(key: "aKey"), 4.2);
    });

    test("keeps a string", () async {
      await properties.store<String>(key: "aKey", value: "a value");

      expect(await properties.load<String>(key: "aKey"), "a value");
    });

    test("keeps a list of strings", () async {
      await properties.store<List<String>>(key: "aKey", value: ["a", "b"]);

      expect(await properties.load<List<String>>(key: "aKey"), ["a", "b"]);
    });

    test("returns true once the value is kept", () async {
      expect(await properties.store<int>(key: "aKey", value: 42), isTrue);
    });

    test("forgets the value when it is given none", () async {
      await properties.store<int>(key: "aKey", value: 42);

      await properties.store<int>(key: "aKey", value: null);

      expect(await properties.load<int>(key: "aKey"), isNull);
    });

    test("replaces the value which was kept under the same key", () async {
      await properties.store<int>(key: "aKey", value: 42);

      await properties.store<int>(key: "aKey", value: 43);

      expect(await properties.load<int>(key: "aKey"), 43);
    });

    test("refuses a type it cannot keep", () async {
      expect(
        () => properties.store<Duration>(key: "aKey", value: const Duration(seconds: 1)),
        throwsA(isA<ActUnsupportedTypeError<Duration>>()),
      );
    });
  });

  group("PropertiesSingleton.load", () {
    test("returns null for a key which was never stored", () async {
      expect(await properties.load<int>(key: "aKey"), isNull);
    });

    test("refuses a type it cannot read", () async {
      expect(
        () => properties.load<Duration>(key: "aKey"),
        throwsA(isA<ActUnsupportedTypeError<Duration>>()),
      );
    });
  });

  group("PropertiesSingleton.delete", () {
    test("forgets the value of the key given", () async {
      await properties.store<int>(key: "aKey", value: 42);

      await properties.delete(key: "aKey");

      expect(await properties.load<int>(key: "aKey"), isNull);
    });

    test("accepts to forget a key which was never stored", () async {
      await expectLater(properties.delete(key: "aKey"), completes);
    });
  });

  group("PropertiesSingleton.deleteAll", () {
    test("forgets every value which was kept", () async {
      await properties.store<int>(key: "aKey", value: 42);
      await properties.store<String>(key: "anotherKey", value: "a value");

      await properties.deleteAll();

      expect(await properties.load<int>(key: "aKey"), isNull);
      expect(await properties.load<String>(key: "anotherKey"), isNull);
    });
  });
}
