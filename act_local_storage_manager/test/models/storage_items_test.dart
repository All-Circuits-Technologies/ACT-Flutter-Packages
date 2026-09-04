// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_local_storage_manager/src/services/properties_singleton.dart';
import 'package:act_local_storage_manager/src/services/secrets_singleton.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The values an application keeps as an enum rather than as a string.
enum _Theme {
  /// The theme of the application when the device is light.
  light,

  /// The theme of the application when the device is dark.
  dark;

  /// Reads the theme from the name it is stored under.
  static _Theme? parse(String value) =>
      _Theme.values.where((theme) => theme.name == value).firstOrNull;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  setUp(() async {
    FakeGlobalManager.install();
    FlutterSecureStorage.setMockInitialValues({});
    await PropertiesSingleton.createInstance().deleteAll();
    SecretsSingleton.createInstance();
  });

  group("AbsStorageItem", () {
    test("equals another item which watches the same key", () {
      expect(const SecretItem<String>("aKey"), const SecretItem<String>("aKey"));
    });

    test("differs from an item which watches another key", () {
      expect(const SecretItem<String>("aKey"), isNot(const SecretItem<String>("anotherKey")));
    });

    test("differs from a secret which is not migrated to a new device", () {
      expect(
        const SecretItem<String>("aKey"),
        isNot(const SecretItem<String>("aKey", doNotMigrate: true)),
      );
    });
  });

  group("SharedPreferencesItem", () {
    test("returns null before anything has been stored", () async {
      expect(await SharedPreferencesItem<int>("aKey").load(), isNull);
    });

    test("returns the value which has been stored", () async {
      final item = SharedPreferencesItem<int>("aKey");

      await item.store(42);

      expect(await item.load(), 42);
    });

    test("returns the value another item stored under the same key", () async {
      await SharedPreferencesItem<int>("aKey").store(42);

      expect(await SharedPreferencesItem<int>("aKey").load(), 42);
    });

    test("forgets the value when it is deleted", () async {
      final item = SharedPreferencesItem<int>("aKey");
      await item.store(42);

      await item.delete();

      expect(await item.load(), isNull);
    });

    test("forgets the value when it is stored as null", () async {
      final item = SharedPreferencesItem<int>("aKey");
      await item.store(42);

      await item.store(null);

      expect(await item.load(), isNull);
    });

    test("pushes the value it stores on its stream", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = expectLater(item.updateStream, emits(42));

      await item.store(42);

      await pushed;
    });

    test("pushes nothing when the value is deleted", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = <Object?>[];
      item.updateStream.listen(pushed.add);
      await item.store(42);

      await item.delete();
      await pumpEventQueue();

      expect(pushed, [42]);
    });
  });

  group("SharedPrefsItemWithParser", () {
    /// Builds an item which keeps a theme as the name it goes by.
    SharedPrefsItemWithParser<_Theme, String> anItem() =>
        SharedPrefsItemWithParser<_Theme, String>(
          "theme",
          parser: _Theme.parse,
          castTo: (theme) => theme.name,
        );

    test("returns the value it parses from what was stored", () async {
      final item = anItem();

      await item.store(_Theme.dark);

      expect(await item.load(), _Theme.dark);
    });

    test("stores the value the way the caller casts it", () async {
      await anItem().store(_Theme.dark);

      expect(await SharedPreferencesItem<String>("theme").load(), "dark");
    });

    test("returns null before anything has been stored", () async {
      expect(await anItem().load(), isNull);
    });

    test("returns null when what was stored cannot be parsed", () async {
      await SharedPreferencesItem<String>("theme").store("purple");

      expect(await anItem().load(), isNull);
    });

    test("forgets the value when it is stored as null", () async {
      final item = anItem();
      await item.store(_Theme.dark);

      await item.store(null);

      expect(await item.load(), isNull);
    });

    test("refuses to store a value which cannot be cast", () async {
      final item = SharedPrefsItemWithParser<_Theme, String>(
        "theme",
        parser: _Theme.parse,
        castTo: (theme) => null,
      );

      expect(await item.store(_Theme.dark), isFalse);
    });
  });

  group("SecretItem", () {
    test("returns null before anything has been stored", () async {
      expect(await const SecretItem<String>("aKey").load(), isNull);
    });

    test("returns the secret which has been stored", () async {
      const item = SecretItem<String>("aKey");

      await item.store("a value");

      expect(await item.load(), "a value");
    });

    test("keeps a boolean as a secret", () async {
      const item = SecretItem<bool>("aKey");

      await item.store(true);

      expect(await item.load(), isTrue);
    });

    test("forgets the secret when it is deleted", () async {
      const item = SecretItem<String>("aKey");
      await item.store("a value");

      await item.delete();

      expect(await item.load(), isNull);
    });

    test("forgets the secret when it is stored as null", () async {
      const item = SecretItem<String>("aKey");
      await item.store("a value");

      await item.store(null);

      expect(await item.load(), isNull);
    });
  });

  group("SecretItemWithParser", () {
    /// Builds an item which keeps a theme as the name it goes by.
    SecretItemWithParser<_Theme, String> anItem() => SecretItemWithParser<_Theme, String>(
      "theme",
      parser: _Theme.parse,
      castTo: (theme) => theme.name,
    );

    test("returns the value it parses from what was stored", () async {
      final item = anItem();

      await item.store(_Theme.dark);

      expect(await item.load(), _Theme.dark);
    });

    test("stores the value the way the caller casts it", () async {
      await anItem().store(_Theme.dark);

      expect(await const SecretItem<String>("theme").load(), "dark");
    });

    test("returns null when what was stored cannot be parsed", () async {
      await const SecretItem<String>("theme").store("purple");

      expect(await anItem().load(), isNull);
    });
  });
}
