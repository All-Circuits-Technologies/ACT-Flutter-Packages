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

/// A secret item which tells what it gives to its storage with each access.
class _SecretItemProbe extends SecretItem<String> {
  /// What the item gives to its storage with each access
  Object? get extraGiven => storageExtra;

  /// Class constructor
  const _SecretItemProbe(super.key, {super.doNotMigrate});
}

/// Collects the values [item] pushes on its update stream from now on.
List<T?> _listen<T>(AbsStorageItem<T> item) {
  final pushed = <T?>[];
  item.updateStream.listen(pushed.add);
  return pushed;
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
      expect(await const SharedPreferencesItem<int>("aKey").load(), isNull);
    });

    test("returns the value which has been stored", () async {
      const item = SharedPreferencesItem<int>("aKey");

      await item.store(42);

      expect(await item.load(), 42);
    });

    test("returns the value another item stored under the same key", () async {
      await const SharedPreferencesItem<int>("aKey").store(42);

      expect(await const SharedPreferencesItem<int>("aKey").load(), 42);
    });

    test("forgets the value when it is deleted", () async {
      const item = SharedPreferencesItem<int>("aKey");
      await item.store(42);

      await item.delete();

      expect(await item.load(), isNull);
    });

    test("forgets the value when it is stored as null", () async {
      const item = SharedPreferencesItem<int>("aKey");
      await item.store(42);

      await item.store(null);

      expect(await item.load(), isNull);
    });

    test("pushes the value it stores, with the type of the item", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = <int?>[];
      item.updateStream.listen(pushed.add);

      await item.store(42);
      await pumpEventQueue();

      expect(pushed, [42]);
    });

    test("pushes the value again when the same value is stored again", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await item.store(42);
      await item.store(42);
      await pumpEventQueue();

      expect(pushed, [42, 42]);
    });

    test("pushes null when the value is deleted", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);
      await item.store(42);

      await item.delete();
      await pumpEventQueue();

      expect(pushed, [42, null]);
    });

    test("pushes a single null when the value is stored as null", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await item.store(null);
      await pumpEventQueue();

      expect(pushed, [null]);
    });

    test("pushes null when the properties are cleared", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await PropertiesSingleton.instance.deleteAll();
      await pumpEventQueue();

      expect(pushed, [null]);
    });

    test("pushes the value another item stores under the same key", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await const SharedPreferencesItem<int>("aKey").store(42);
      await pumpEventQueue();

      expect(pushed, [42]);
    });

    test("pushes nothing which is stored under another key", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await const SharedPreferencesItem<int>("anotherKey").store(42);
      await pumpEventQueue();

      expect(pushed, isEmpty);
    });

    test("pushes null when the value stored under its key is not of its type", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await const SharedPreferencesItem<String>("aKey").store("a text");
      await pumpEventQueue();

      expect(pushed, [null]);
    });

    test("pushes nothing which is written to the secrets", () async {
      const item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await const SecretItem<int>("aKey").store(42);
      await pumpEventQueue();

      expect(pushed, isEmpty);
    });
  });

  group("SharedPrefsItemWithParser", () {
    /// Builds an item which keeps a theme as the name it goes by.
    SharedPrefsItemWithParser<_Theme, String> anItem() => SharedPrefsItemWithParser<_Theme, String>(
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

      expect(await const SharedPreferencesItem<String>("theme").load(), "dark");
    });

    test("returns null before anything has been stored", () async {
      expect(await anItem().load(), isNull);
    });

    test("returns null when what was stored cannot be parsed", () async {
      await const SharedPreferencesItem<String>("theme").store("purple");

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

    test("pushes the value it stores once, with its type", () async {
      final item = anItem();
      final pushed = <_Theme?>[];
      item.updateStream.listen(pushed.add);

      await item.store(_Theme.dark);
      await pumpEventQueue();

      expect(pushed, [_Theme.dark]);
    });

    test("pushes null when the value is stored as null", () async {
      final item = anItem();
      final pushed = _listen(item);

      await item.store(null);
      await pumpEventQueue();

      expect(pushed, [null]);
    });

    test("pushes nothing when the value cannot be cast", () async {
      final item = SharedPrefsItemWithParser<_Theme, String>(
        "theme",
        parser: _Theme.parse,
        castTo: (theme) => null,
      );
      final pushed = _listen(item);

      await item.store(_Theme.dark);
      await pumpEventQueue();

      expect(pushed, isEmpty);
    });

    test("pushes the value it parses from what another item stores", () async {
      final item = anItem();
      final pushed = _listen(item);

      await const SharedPreferencesItem<String>("theme").store("dark");
      await pumpEventQueue();

      expect(pushed, [_Theme.dark]);
    });

    test("pushes null when what another item stores cannot be parsed", () async {
      final item = anItem();
      final pushed = _listen(item);

      await const SharedPreferencesItem<String>("theme").store("purple");
      await pumpEventQueue();

      expect(pushed, [null]);
    });

    test("is seen by an item of the stored type, as it was stored", () async {
      const item = SharedPreferencesItem<String>("theme");
      final pushed = _listen(item);

      await anItem().store(_Theme.dark);
      await pumpEventQueue();

      expect(pushed, ["dark"]);
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

  group("SecretItem.updateStream", () {
    test("pushes the secret it stores, with the type of the item", () async {
      const item = SecretItem<String>("aKey");
      final pushed = <String?>[];
      item.updateStream.listen(pushed.add);

      await item.store("a value");
      await pumpEventQueue();

      expect(pushed, ["a value"]);
    });

    test("pushes null when the secret is deleted", () async {
      const item = SecretItem<String>("aKey");
      final pushed = _listen(item);

      await item.delete();
      await pumpEventQueue();

      expect(pushed, [null]);
    });

    test("pushes null when the secrets are cleared", () async {
      const item = SecretItem<String>("aKey");
      final pushed = _listen(item);

      await SecretsSingleton.instance.deleteAll();
      await pumpEventQueue();

      expect(pushed, [null]);
    });
  });

  group("SecretItem.storageExtra", () {
    test("gives the storage whether the secret is kept on this device only", () {
      expect(const _SecretItemProbe("aKey", doNotMigrate: true).extraGiven, isTrue);
      expect(const _SecretItemProbe("aKey").extraGiven, isFalse);
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

    test("pushes the value it stores once, with its type", () async {
      final item = anItem();
      final pushed = <_Theme?>[];
      item.updateStream.listen(pushed.add);

      await item.store(_Theme.dark);
      await pumpEventQueue();

      expect(pushed, [_Theme.dark]);
    });

    test("pushes null when the value is deleted", () async {
      final item = anItem();
      final pushed = _listen(item);

      await item.delete();
      await pumpEventQueue();

      expect(pushed, [null]);
    });

    test("pushes nothing when the value cannot be cast", () async {
      final item = SecretItemWithParser<_Theme, String>(
        "theme",
        parser: _Theme.parse,
        castTo: (theme) => null,
      );
      final pushed = _listen(item);

      await item.store(_Theme.dark);
      await pumpEventQueue();

      expect(pushed, isEmpty);
    });
  });
}
