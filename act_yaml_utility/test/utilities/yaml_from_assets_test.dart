// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';
import 'dart:typed_data';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_yaml_utility/act_yaml_utility.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The channel the asset bundle reads the files through.
const _assetsChannel = "flutter/assets";

/// Serves [contents] on the asset channel, and lets the other keys fail as a missing asset does.
void _serveAssets(Map<String, String> contents) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
    _assetsChannel,
    (message) async {
      final key = utf8.decode(message!.buffer.asUint8List());
      final content = contents[key];
      if (content == null) {
        return null;
      }

      return ByteData.sublistView(Uint8List.fromList(utf8.encode(content)));
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
      _assetsChannel,
      null,
    ),
  );

  group("YamlFromAssets.loadYaml", () {
    test("returns the content of the file as plain Dart objects", () async {
      _serveAssets({"assets/config.yaml": "server:\n  host: example.com"});

      final result = await YamlFromAssets.loadYaml("assets/config.yaml", cache: false);

      expect(result.status, AssetsBundleResult.ok);
      expect(result.data, {
        "server": {"host": "example.com"},
      });
    });

    test("guesses the extension when the key has none", () async {
      _serveAssets({"assets/config.yml": "a: 1"});

      final result = await YamlFromAssets.loadYaml("assets/config", cache: false);

      expect(result.status, AssetsBundleResult.ok);
      expect(result.data, {"a": 1});
    });

    test("tries the extensions in the order it is given", () async {
      _serveAssets({"assets/config.yaml": "a: 1", "assets/config.json": '{"a": 2}'});

      final result = await YamlFromAssets.loadYaml(
        "assets/config",
        cache: false,
        yamlFileTypes: const [
          YamlFromAssets.jsonFileType,
          YamlFromAssets.yamlFileType,
        ],
      );

      expect(result.data, {"a": 2});
    });

    test("reads a JSON file, which is valid YAML", () async {
      _serveAssets({"assets/config.json": '{"a": 1}'});

      final result = await YamlFromAssets.loadYaml("assets/config.json", cache: false);

      expect(result.data, {"a": 1});
    });

    test("reports the file as not found when no extension matches", () async {
      _serveAssets(const {});

      final result = await YamlFromAssets.loadYaml("assets/missing", cache: false);

      expect(result.status, AssetsBundleResult.notFound);
      expect(result.data, isNull);
    });

    test("does not guess the extension when the key already has one", () async {
      _serveAssets({"assets/config.yaml": "a: 1"});

      final result = await YamlFromAssets.loadYaml("assets/config.json", cache: false);

      expect(result.status, AssetsBundleResult.notFound);
    });

    test("reports a generic error when the file is not YAML", () async {
      _serveAssets({"assets/broken.yaml": "a:\n  - 1\n b: 2"});

      final result = await YamlFromAssets.loadYaml("assets/broken.yaml", cache: false);

      expect(result.status, AssetsBundleResult.genericError);
      expect(result.data, isNull);
    });
  });

  group("YamlFromAssets.loadYamlMap", () {
    test("returns the object at the root of the file", () async {
      _serveAssets({"assets/config.yaml": "a: 1"});

      final result = await YamlFromAssets.loadYamlMap("assets/config.yaml", cache: false);

      expect(result.status, AssetsBundleResult.ok);
      expect(result.data, {"a": 1});
    });

    test("reports a generic error when the root is a list", () async {
      _serveAssets({"assets/config.yaml": "- 1"});

      final result = await YamlFromAssets.loadYamlMap("assets/config.yaml", cache: false);

      expect(result.status, AssetsBundleResult.genericError);
      expect(result.data, isNull);
    });

    test("returns an empty object for an empty file", () async {
      _serveAssets({"assets/config.yaml": ""});

      final result = await YamlFromAssets.loadYamlMap("assets/config.yaml", cache: false);

      expect(result.status, AssetsBundleResult.ok);
      expect(result.data, isEmpty);
    });

    test("reports the file as not found when it is not in the bundle", () async {
      _serveAssets(const {});

      final result = await YamlFromAssets.loadYamlMap("assets/missing.yaml", cache: false);

      expect(result.status, AssetsBundleResult.notFound);
      expect(result.data, isNull);
    });
  });

  group("YamlFromAssets.loadYamlList", () {
    test("returns the list at the root of the file", () async {
      _serveAssets({"assets/items.yaml": "- 1\n- 2"});

      final result = await YamlFromAssets.loadYamlList("assets/items.yaml", cache: false);

      expect(result.status, AssetsBundleResult.ok);
      expect(result.data, [1, 2]);
    });

    test("reports a generic error when the root is an object", () async {
      _serveAssets({"assets/items.yaml": "a: 1"});

      final result = await YamlFromAssets.loadYamlList("assets/items.yaml", cache: false);

      expect(result.status, AssetsBundleResult.genericError);
      expect(result.data, isNull);
    });

    test("returns an empty list for an empty file", () async {
      _serveAssets({"assets/items.yaml": ""});

      final result = await YamlFromAssets.loadYamlList("assets/items.yaml", cache: false);

      expect(result.status, AssetsBundleResult.ok);
      expect(result.data, isEmpty);
    });
  });
}
