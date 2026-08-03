// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui' as ui;

import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_remote_storage_ui/act_remote_storage_ui.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_image_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeImageStorageService storage;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    storage = FakeImageStorageService();
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    await globalManager.reset();
    FakeAssets.stop();
  });

  /// Builds the storage manager of an application which displays the images it downloads.
  Future<FakeImageStorageManager> aManager() async {
    final config = await FakeImageStorageConfig.build();
    addTearDown(config.disposeLifeCycle);
    globalManager.managers.registerSingleton<FakeImageStorageConfig>(config);

    final manager = FakeImageStorageManager(storage);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("MixinImageCacheService.createKey", () {
    test("names the file alone when no size is asked for", () {
      final key = MixinImageCacheService.createKey(
        fileId: "aFile",
        maxWidth: null,
        maxHeight: null,
      );

      expect(key, "aFile");
    });

    test("names the width and the height of the image it stands for", () {
      final key = MixinImageCacheService.createKey(fileId: "aFile", maxWidth: 20, maxHeight: 10);

      expect(key, "20_10_aFile");
    });

    test("names the height alone when the width is left out", () {
      final key = MixinImageCacheService.createKey(fileId: "aFile", maxWidth: null, maxHeight: 10);

      expect(key, "10_aFile");
    });
  });

  group("MixinImageCacheService.createKeyFromDouble", () {
    test("rounds a size up to the pixel above", () {
      final key = MixinImageCacheService.createKeyFromDouble(
        fileId: "aFile",
        maxWidth: 19.2,
        maxHeight: 9.7,
      );

      expect(key, "20_10_aFile");
    });

    test("leaves out a size which has no bound", () {
      final key = MixinImageCacheService.createKeyFromDouble(
        fileId: "aFile",
        maxWidth: double.infinity,
        maxHeight: 10,
      );

      expect(key, "10_aFile");
    });
  });

  group("MixinImageCacheService.getImageFile", () {
    test("asks the storage for the image when the cache is left out", () async {
      final manager = await aManager();

      await manager.getImageFile("aFile", useCache: false);

      expect(storage.askedFiles, ["aFile"]);
    });

    test("goes to the storage when the cache is asked for and the application uses none", () async {
      final manager = await aManager();

      await manager.getImageFile("aFile");

      expect(storage.askedFiles, ["aFile"]);
    });

    test("warns when the cache is asked for and the application uses none", () async {
      final manager = await aManager();

      final lines = await _consoleLines(() => manager.getImageFile("aFile"));

      expect(lines.single, contains("[warn]"));
    });

    test("hands back what the storage answered", () async {
      final manager = await aManager();
      storage.fileResult = StorageRequestResult.accessDenied;

      final result = await manager.getImageFile("aFile", useCache: false);

      expect(result.result, StorageRequestResult.accessDenied);
    });
  });

  group("MixinImageCacheService.clearImageFileFromCache", () {
    /// Puts the image of [key] in the cache Flutter paints from, and tells whether it is still
    /// there.
    Future<bool> Function() aPaintedImage(String key) {
      PaintingBinding.instance.imageCache.putIfAbsent(
        key,
        () => OneFrameImageStreamCompleter(Future.value(ImageInfo(image: _anImage()))),
      );

      return () async => PaintingBinding.instance.imageCache.containsKey(key);
    }

    test("drops the image of the file from the cache Flutter paints from", () async {
      final manager = await aManager();
      await manager.getImageFile("aFile", useCache: false);
      final painted = aPaintedImage("aFile");

      await manager.clearImageFileFromCache("aFile");

      expect(await painted(), isFalse);
    });

    test("drops the image of every size the file was asked for", () async {
      final manager = await aManager();
      await manager.getImageFile("aFile", useCache: false, maxWidth: 20, maxHeight: 10);
      final painted = aPaintedImage("20_10_aFile");

      await manager.clearImageFileFromCache("aFile");

      expect(await painted(), isFalse);
    });

    test("drops the image of the key the caller named", () async {
      final manager = await aManager();
      await manager.getImageFile("aFile", useCache: false, flutterPaintingImageKey: "aKey");
      final painted = aPaintedImage("aKey");

      await manager.clearImageFileFromCache("aFile");

      expect(await painted(), isFalse);
    });

    test("leaves the cache Flutter paints from alone when it is told to", () async {
      final manager = await aManager();
      await manager.getImageFile("aFile", useCache: false);
      final painted = aPaintedImage("aFile");

      await manager.clearImageFileFromCache("aFile", clearPaintingCache: false);

      expect(await painted(), isTrue);
    });

    test("keeps the image of a file the storage refused to answer for", () async {
      final manager = await aManager();
      storage.fileResult = StorageRequestResult.accessDenied;
      await manager.getImageFile("aFile", useCache: false);
      final painted = aPaintedImage("aFile");

      await manager.clearImageFileFromCache("aFile");

      expect(await painted(), isTrue);
    });
  });
}

/// Runs [body] and returns the lines it wrote to the console.
///
/// The manager logs under the logger of the application, which a test does not hold; the console is
/// where those messages come out, and it is the only place a test can read them from.
Future<List<String>> _consoleLines(Future<void> Function() body) async {
  final lines = <String>[];

  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(print: (self, parent, zone, line) => lines.add(line)),
  );

  return lines;
}

/// An image of one pixel, which is what the tests put in the cache Flutter paints from.
ui.Image _anImage() {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(const Color(0xFF00FF00), BlendMode.src);

  return recorder.endRecording().toImageSync(1, 1);
}
