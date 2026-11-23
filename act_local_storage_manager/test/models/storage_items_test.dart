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

/// Collects the values [item] pushes on its update stream.
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
      expect(SecretItem<String>("aKey"), SecretItem<String>("aKey"));
    });

    test("differs from an item which watches another key", () {
      expect(SecretItem<String>("aKey"), isNot(SecretItem<String>("anotherKey")));
    });

    test("differs from a secret which is not migrated to a new device", () {
      expect(
        SecretItem<String>("aKey"),
        isNot(SecretItem<String>("aKey", doNotMigrate: true)),
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

    test("pushes the value it stores, with the type of the item", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = <int?>[];
      item.updateStream.listen(pushed.add);

      await item.store(42);
      await pumpEventQueue();

      expect(pushed, [42]);
    });

    test("pushes the value again when the same value is stored again", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await item.store(42);
      await item.store(42);
      await pumpEventQueue();

      expect(pushed, [42, 42]);
    });

    test("pushes null when the value is deleted", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);
      await item.store(42);

      await item.delete();
      await pumpEventQueue();

      expect(pushed, [42, null]);
    });

    test("pushes null when the value is stored as null", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);
      await item.store(42);

      await item.store(null);
      await pumpEventQueue();

      expect(pushed, [42, null]);
    });

    test("pushes null when nothing was stored before the deletion", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await item.delete();
      await pumpEventQueue();

      expect(pushed, [null]);
    });

    test("ends its stream once it is disposed", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final ended = expectLater(item.updateStream, emitsDone);

      await item.disposeLifeCycle();

      await ended;
    });

    test("still stores, but pushes nothing, once it is disposed", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);
      await item.disposeLifeCycle();

      await item.store(42);
      await pumpEventQueue();

      expect(await item.load(), 42);
      expect(pushed, isEmpty);
    });

    test("pushes nothing which is stored through another item", () async {
      final item = SharedPreferencesItem<int>("aKey");
      final pushed = _listen(item);

      await SharedPreferencesItem<int>("aKey").store(42);
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

    test("pushes the parsed value once, with its type", () async {
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
      await item.store(_Theme.dark);

      await item.store(null);
      await pumpEventQueue();

      expect(pushed, [_Theme.dark, null]);
    });

    test("refuses to store a value which cannot be cast", () async {
      final item = SharedPrefsItemWithParser<_Theme, String>(
        "theme",
        parser: _Theme.parse,
        castTo: (theme) => null,
      );

      expect(await item.store(_Theme.dark), isFalse);
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
  });

  group("SecretItem", () {
    test("returns null before anything has been stored", () async {
      expect(await SecretItem<String>("aKey").load(), isNull);
    });

    test("returns the secret which has been stored", () async {
      final item = SecretItem<String>("aKey");

      await item.store("a value");

      expect(await item.load(), "a value");
    });

    test("keeps a boolean as a secret", () async {
      final item = SecretItem<bool>("aKey");

      await item.store(true);

      expect(await item.load(), isTrue);
    });

    test("forgets the secret when it is deleted", () async {
      final item = SecretItem<String>("aKey");
      await item.store("a value");

      await item.delete();

      expect(await item.load(), isNull);
    });

    test("forgets the secret when it is stored as null", () async {
      final item = SecretItem<String>("aKey");
      await item.store("a value");

      await item.store(null);

      expect(await item.load(), isNull);
    });

    test("pushes the secret it stores, with the type of the item", () async {
      final item = SecretItem<String>("aKey");
      final pushed = <String?>[];
      item.updateStream.listen(pushed.add);

      await item.store("a value");
      await pumpEventQueue();

      expect(pushed, ["a value"]);
    });

    test("ends its stream once it is disposed", () async {
      final item = SecretItem<String>("aKey");
      final ended = expectLater(item.updateStream, emitsDone);

      await item.disposeLifeCycle();

      await ended;
    });

    test("pushes null when the secret is deleted", () async {
      final item = SecretItem<String>("aKey");
      final pushed = _listen(item);
      await item.store("a value");

      await item.delete();
      await pumpEventQueue();

      expect(pushed, ["a value", null]);
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

      expect(await SecretItem<String>("theme").load(), "dark");
    });

    test("returns null when what was stored cannot be parsed", () async {
      await SecretItem<String>("theme").store("purple");

      expect(await anItem().load(), isNull);
    });

    test("pushes the parsed value once, with its type", () async {
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
      await item.store(_Theme.dark);

      await item.delete();
      await pumpEventQueue();

      expect(pushed, [_Theme.dark, null]);
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
