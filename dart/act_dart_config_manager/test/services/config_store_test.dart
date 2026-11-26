// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:test/test.dart';

/// Creates the store with the given [configs].
ConfigStore _createStore(Map<String, dynamic> configs) =>
    ConfigStore.create(logger: const SilentLogger(), configs: configs);

void main() {
  tearDown(() => ConfigStore.instanceOrNull?.dispose());

  group("ConfigStore.instance", () {
    test("throws when the store hasn't been created yet", () {
      expect(() => ConfigStore.instance, throwsA(isA<ActSingletonNotCreatedError>()));
    });

    test("returns the created store", () {
      final created = _createStore({});

      expect(ConfigStore.instance, same(created));
    });
  });

  group("ConfigStore.instanceOrNull", () {
    test("returns null when the store hasn't been created yet", () {
      expect(ConfigStore.instanceOrNull, isNull);
    });

    test("returns the created store", () {
      final created = _createStore({});

      expect(ConfigStore.instanceOrNull, same(created));
    });
  });

  group("ConfigStore.create", () {
    test("refuses to create the store twice", () {
      _createStore({});

      expect(() => _createStore({}), throwsA(isA<ActSingletonAlreadyCreatedError>()));
    });

    test("accepts to create the store again once it has been disposed", () {
      final first = _createStore({"a": 1});
      first.dispose();

      final second = _createStore({"a": 2});

      expect(second, isNot(same(first)));
      expect(second.tryToGet<int>("a"), 2);
    });
  });

  group("ConfigStore.dispose", () {
    test("releases the store", () {
      final store = _createStore({});

      store.dispose();

      expect(ConfigStore.instanceOrNull, isNull);
    });

    test("leaves the current store in place when an older one is disposed", () {
      final first = _createStore({"a": 1});
      first.dispose();
      final second = _createStore({"a": 2});

      first.dispose();

      expect(ConfigStore.instanceOrNull, same(second));
    });
  });

  group("ConfigStore.tryToGet", () {
    test("returns the value stored at the root of the configuration", () {
      final store = _createStore({"host": "example.com"});

      expect(store.tryToGet<String>("host"), "example.com");
    });

    test("walks down the maps of the configuration to find a nested value", () {
      final store = _createStore({
        "firebase": {
          "crash": {"enable": true},
        },
      });

      expect(store.tryToGet<bool>("firebase.crash.enable"), isTrue);
    });

    test("returns null when the key is missing", () {
      final store = _createStore({"host": "example.com"});

      expect(store.tryToGet<String>("port"), isNull);
    });

    test("returns null when a step of the key is missing", () {
      final store = _createStore({
        "logs": {"level": "warning"},
      });

      expect(store.tryToGet<String>("logs.console.level"), isNull);
    });

    test("returns null when a step of the key is not a map", () {
      final store = _createStore({
        "logs": {"level": "warning"},
      });

      expect(store.tryToGet<String>("logs.level.name"), isNull);
    });

    test("returns null when the value is not of the expected type", () {
      final store = _createStore({"port": "8080"});

      expect(store.tryToGet<int>("port"), isNull);
    });

    test("returns the map itself when the key stops on a map", () {
      final store = _createStore({
        "logs": {"level": "warning"},
      });

      expect(store.tryToGet<Map<String, dynamic>>("logs"), {"level": "warning"});
    });

    test("ignores the empty steps of the key", () {
      final store = _createStore({
        "logs": {"level": "warning"},
      });

      expect(store.tryToGet<String>(".logs..level."), "warning");
    });

    test("returns null for an empty key", () {
      final store = _createStore({"host": "example.com"});

      expect(store.tryToGet<String>(""), isNull);
    });
  });

  group("ConfigStore.tryToGetList", () {
    test("returns the list stored at the given key", () {
      final store = _createStore({
        "hosts": ["first", "second"],
      });

      expect(store.tryToGetList<String>("hosts"), ["first", "second"]);
    });

    test("returns the list of a nested key", () {
      final store = _createStore({
        "server": {
          "ports": [80, 443],
        },
      });

      expect(store.tryToGetList<int>("server.ports"), [80, 443]);
    });

    test("returns null when the key is missing", () {
      final store = _createStore({});

      expect(store.tryToGetList<String>("hosts"), isNull);
    });

    test("returns null when the value is not a list", () {
      final store = _createStore({"hosts": "first"});

      expect(store.tryToGetList<String>("hosts"), isNull);
    });

    test("returns null when one element of the list is not of the expected type", () {
      final store = _createStore({
        "ports": [80, "443"],
      });

      expect(store.tryToGetList<int>("ports"), isNull);
    });

    test("returns an empty list when the stored list is empty", () {
      final store = _createStore({"hosts": <dynamic>[]});

      expect(store.tryToGetList<String>("hosts"), isEmpty);
    });

    test("returns a list which cannot be grown", () {
      final store = _createStore({
        "hosts": ["first"],
      });

      expect(() => store.tryToGetList<String>("hosts")!.add("second"), throwsUnsupportedError);
    });
  });
}
