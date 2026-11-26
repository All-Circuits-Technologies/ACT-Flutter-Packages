// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/services/config_singleton.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates the singleton with the given [configs].
ConfigSingleton _createSingleton(Map<String, dynamic> configs) =>
    ConfigSingleton.createInstance(logger: const SilentLogger(), configs: configs);

void main() {
  tearDown(() => ConfigSingleton.instanceOrNull?.disposeLifeCycle());

  group("ConfigSingleton.instance", () {
    test("throws when the singleton hasn't been created yet", () {
      expect(() => ConfigSingleton.instance, throwsA(isA<ActSingletonNotCreatedError>()));
    });

    test("returns the created singleton", () {
      final created = _createSingleton({});

      expect(ConfigSingleton.instance, same(created));
    });
  });

  group("ConfigSingleton.instanceOrNull", () {
    test("returns null when the singleton hasn't been created yet", () {
      expect(ConfigSingleton.instanceOrNull, isNull);
    });

    test("returns the created singleton", () {
      final created = _createSingleton({});

      expect(ConfigSingleton.instanceOrNull, same(created));
    });
  });

  group("ConfigSingleton.createInstance", () {
    test("refuses to create the singleton twice", () {
      _createSingleton({});

      expect(() => _createSingleton({}), throwsA(isA<ActSingletonAlreadyCreatedError>()));
    });

    test("accepts to create the singleton again once it has been disposed", () async {
      final first = _createSingleton({"a": 1});
      await first.disposeLifeCycle();

      final second = _createSingleton({"a": 2});

      expect(second, isNot(same(first)));
      expect(second.tryToGet<int>("a"), 2);
    });
  });

  group("ConfigSingleton.disposeLifeCycle", () {
    test("releases the singleton", () async {
      final singleton = _createSingleton({});

      await singleton.disposeLifeCycle();

      expect(ConfigSingleton.instanceOrNull, isNull);
    });

    test("leaves the current singleton in place when an older one is disposed", () async {
      final first = _createSingleton({"a": 1});
      await first.disposeLifeCycle();
      final second = _createSingleton({"a": 2});

      await first.disposeLifeCycle();

      expect(ConfigSingleton.instanceOrNull, same(second));
    });
  });

  group("ConfigSingleton.tryToGet", () {
    test("returns the value stored at the root of the configuration", () {
      final singleton = _createSingleton({"host": "example.com"});

      expect(singleton.tryToGet<String>("host"), "example.com");
    });

    test("walks down the maps of the configuration to find a nested value", () {
      final singleton = _createSingleton({
        "firebase": {
          "crash": {"enable": true},
        },
      });

      expect(singleton.tryToGet<bool>("firebase.crash.enable"), isTrue);
    });

    test("returns null when the key is missing", () {
      final singleton = _createSingleton({"host": "example.com"});

      expect(singleton.tryToGet<String>("port"), isNull);
    });

    test("returns null when a step of the key is missing", () {
      final singleton = _createSingleton({
        "logs": {"level": "warning"},
      });

      expect(singleton.tryToGet<String>("logs.console.level"), isNull);
    });

    test("returns null when a step of the key is not a map", () {
      final singleton = _createSingleton({
        "logs": {"level": "warning"},
      });

      expect(singleton.tryToGet<String>("logs.level.name"), isNull);
    });

    test("returns null when the value is not of the expected type", () {
      final singleton = _createSingleton({"port": "8080"});

      expect(singleton.tryToGet<int>("port"), isNull);
    });

    test("returns the map itself when the key stops on a map", () {
      final singleton = _createSingleton({
        "logs": {"level": "warning"},
      });

      expect(singleton.tryToGet<Map<String, dynamic>>("logs"), {"level": "warning"});
    });

    test("ignores the empty steps of the key", () {
      final singleton = _createSingleton({
        "logs": {"level": "warning"},
      });

      expect(singleton.tryToGet<String>(".logs..level."), "warning");
    });

    test("returns null for an empty key", () {
      final singleton = _createSingleton({"host": "example.com"});

      expect(singleton.tryToGet<String>(""), isNull);
    });
  });

  group("ConfigSingleton.tryToGetList", () {
    test("returns the list stored at the given key", () {
      final singleton = _createSingleton({
        "hosts": ["first", "second"],
      });

      expect(singleton.tryToGetList<String>("hosts"), ["first", "second"]);
    });

    test("returns the list of a nested key", () {
      final singleton = _createSingleton({
        "server": {
          "ports": [80, 443],
        },
      });

      expect(singleton.tryToGetList<int>("server.ports"), [80, 443]);
    });

    test("returns null when the key is missing", () {
      final singleton = _createSingleton({});

      expect(singleton.tryToGetList<String>("hosts"), isNull);
    });

    test("returns null when the value is not a list", () {
      final singleton = _createSingleton({"hosts": "first"});

      expect(singleton.tryToGetList<String>("hosts"), isNull);
    });

    test("returns null when one element of the list is not of the expected type", () {
      final singleton = _createSingleton({
        "ports": [80, "443"],
      });

      expect(singleton.tryToGetList<int>("ports"), isNull);
    });

    test("returns an empty list when the stored list is empty", () {
      final singleton = _createSingleton({"hosts": <dynamic>[]});

      expect(singleton.tryToGetList<String>("hosts"), isEmpty);
    });

    test("returns a list which cannot be grown", () {
      final singleton = _createSingleton({
        "hosts": ["first"],
      });

      expect(() => singleton.tryToGetList<String>("hosts")!.add("second"), throwsUnsupportedError);
    });
  });
}
