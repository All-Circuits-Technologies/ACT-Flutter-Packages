// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
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

  group("AssetsBundleUtility.loadStringFromAssetBundle", () {
    test("returns the content of the file", () async {
      _serveAssets({"assets/config.yaml": "server: example.com"});

      final result = await AssetsBundleUtility.loadStringFromAssetBundle(
        "assets/config.yaml",
        cache: false,
      );

      expect(result.status, AssetsBundleResult.ok);
      expect(result.data, "server: example.com");
    });

    test("reports the file as not found when it is not in the bundle", () async {
      _serveAssets(const {});

      final result = await AssetsBundleUtility.loadStringFromAssetBundle(
        "assets/missing.yaml",
        cache: false,
      );

      expect(result.status, AssetsBundleResult.notFound);
      expect(result.data, isNull);
    });

    test("warns through the logger when the file is not found", () async {
      _serveAssets(const {});
      final logger = FakeLogger();

      await AssetsBundleUtility.loadStringFromAssetBundle(
        "assets/missing.yaml",
        cache: false,
        logger: logger,
      );

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("logs nothing when the file is found", () async {
      _serveAssets({"assets/found.yaml": "a: 1"});
      final logger = FakeLogger();

      await AssetsBundleUtility.loadStringFromAssetBundle(
        "assets/found.yaml",
        cache: false,
        logger: logger,
      );

      expect(logger.records, isEmpty);
    });
  });

  group("AssetsBundleUtility.loadBinaryFromAssetBundle", () {
    test("returns the bytes of the file", () async {
      _serveAssets({"assets/binary.bin": "AB"});

      final result = await AssetsBundleUtility.loadBinaryFromAssetBundle(
        "assets/binary.bin",
        cache: false,
      );

      expect(result.status, AssetsBundleResult.ok);
      expect(result.data, Uint8List.fromList(utf8.encode("AB")));
    });

    test("reports the file as not found when it is not in the bundle", () async {
      _serveAssets(const {});

      final result = await AssetsBundleUtility.loadBinaryFromAssetBundle(
        "assets/missing.bin",
        cache: false,
      );

      expect(result.status, AssetsBundleResult.notFound);
      expect(result.data, isNull);
    });

    test("warns through the logger when the file is not found", () async {
      _serveAssets(const {});
      final logger = FakeLogger();

      await AssetsBundleUtility.loadBinaryFromAssetBundle(
        "assets/missing.bin",
        cache: false,
        logger: logger,
      );

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });
}
