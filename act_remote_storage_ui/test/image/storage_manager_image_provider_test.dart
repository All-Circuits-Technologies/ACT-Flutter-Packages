// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:io';

import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_remote_storage_ui/act_remote_storage_ui.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_image_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeImageStorageService storage;
  late Directory directory;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    storage = FakeImageStorageService();
    directory = await Directory.systemTemp.createTemp("act_remote_storage_ui_test");
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await globalManager.reset();
    FakeAssets.stop();
    await directory.delete(recursive: true);
  });

  /// Registers the storage manager of an application which displays the images it downloads.
  Future<void> anApplication() async {
    final config = await FakeImageStorageConfig.build();
    addTearDown(config.disposeLifeCycle);
    globalManager.managers.registerSingleton<FakeImageStorageConfig>(config);

    final manager = FakeImageStorageManager(storage);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);
    globalManager.managers.registerSingleton<FakeImageStorageManager>(manager);
  }

  /// Builds the provider of the image of [fileId].
  StorageManagerImageProvider<FakeImageStorageManager> aProvider(
    String fileId, {
    double? maxWidth,
    double? maxHeight,
    double? devicePixelRatio,
    bool useCache = false,
  }) => StorageManagerImageProvider<FakeImageStorageManager>(
    fileId: fileId,
    maxWidth: maxWidth,
    maxHeight: maxHeight,
    devicePixelRatio: devicePixelRatio,
    useCache: useCache,
  );

  group("StorageManagerImageProvider.obtainKey", () {
    test("names the file the image comes from", () async {
      await anApplication();

      final key = await aProvider("aFile").obtainKey(ImageConfiguration.empty);

      expect(key, "aFile");
    });

    test("names the size of the image in the pixels of the device", () async {
      await anApplication();

      final key = await aProvider(
        "aFile",
        maxWidth: 10,
        maxHeight: 5,
        devicePixelRatio: 2,
      ).obtainKey(ImageConfiguration.empty);

      expect(key, "20_10_aFile");
    });

    test("leaves out a size which has no bound", () async {
      await anApplication();

      final key = await aProvider(
        "aFile",
        maxWidth: double.infinity,
        devicePixelRatio: 2,
      ).obtainKey(ImageConfiguration.empty);

      expect(key, "aFile");
    });
  });

  group("StorageManagerImageProvider", () {
    test("refuses a size without the pixels of the device to read it in", () async {
      await anApplication();

      expect(() => aProvider("aFile", maxWidth: 10), throwsAssertionError);
    });

    test("takes the storage manager of the application", () async {
      await anApplication();

      expect(() => aProvider("aFile"), returnsNormally);
    });
  });

  group("StorageManagerImageProvider.loadImage", () {
    test("hands over the image of the file the storage answered with", () async {
      await anApplication();
      storage.file = await anImageFile(directory, size: 8);

      final image = await _resolve(aProvider("theImageOfAFile"));

      expect(image.image.width, 8);
    });

    test("asks the storage for the file of the image", () async {
      await anApplication();
      storage.file = await anImageFile(directory);

      await _resolve(aProvider("theFileOfAnImage"));

      expect(storage.askedFiles, ["theFileOfAnImage"]);
    });

    test("resizes the image to the size which was asked for", () async {
      await anApplication();
      storage.file = await anImageFile(directory, size: 8);

      final image = await _resolve(
        aProvider("anImageToResize", maxWidth: 4, maxHeight: 4, devicePixelRatio: 1),
      );

      expect(image.image.width, 4);
    });

    test("gives up when the storage answered no file", () async {
      await anApplication();
      storage.fileResult = StorageRequestResult.genericError;

      await expectLater(_resolve(aProvider("aFileWhichIsNotThere")), throwsA(isA<String>()));
    });
  });
}

/// Loads the image of [provider] and returns what it painted.
Future<ImageInfo> _resolve(ImageProvider<Object> provider) {
  final completer = Completer<ImageInfo>();

  provider
      .resolve(ImageConfiguration.empty)
      .addListener(
        ImageStreamListener(
          (info, _) => completer.complete(info),
          onError: (error, _) => completer.completeError(error),
        ),
      );

  return completer.future;
}
