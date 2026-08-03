// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_remote_storage_ui/act_remote_storage_ui.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_image_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeImageStorageService storage;
  late FakeImageStorageConfig config;
  late FakeImageStorageManager manager;
  late Directory directory;

  // The application of a test is built here rather than inside a test, because the clock of a widget
  // test does not drive the reading of a file nor the drawing of an image: what needs either of them
  // has to happen before the test starts or through `runAsync`.
  setUp(() async {
    globalManager = FakeGlobalManager.install();
    storage = FakeImageStorageService();
    directory = await Directory.systemTemp.createTemp("act_remote_storage_ui_test");
    storage.file = await anImageFile(directory, size: 8);

    config = await FakeImageStorageConfig.build();
    globalManager.managers.registerSingleton<FakeImageStorageConfig>(config);

    manager = FakeImageStorageManager(storage);
    await manager.initLifeCycle();
    globalManager.managers.registerSingleton<FakeImageStorageManager>(manager);
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
    await globalManager.reset();
    FakeAssets.stop();
    await directory.delete(recursive: true);
  });

  /// Displays the image of [fileId] on a page of the application under test.
  Future<void> anImageOf(
    WidgetTester tester,
    String fileId, {
    WidgetBuilder? placeholderBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: StorageManagerImage<FakeImageStorageManager>(
          fileId: fileId,
          useCache: false,
          width: 8,
          height: 8,
          placeholderBuilder: placeholderBuilder,
          errorBuilder: errorBuilder,
        ),
      ),
    ),
  );

  /// Lets the image be read from its file and drawn, and pumps the frames which show it.
  ///
  /// Reading a file and drawing an image both happen outside the clock of the test, one step at a
  /// time, so the real event loop is given a turn and a frame is pumped as many times as the steps
  /// it takes.
  Future<void> theImageIsShown(WidgetTester tester) async {
    for (var turn = 0; turn < 8; turn++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
  }

  group("StorageManagerImage", () {
    testWidgets("reads the image through the provider of the storage manager", (tester) async {
      await anImageOf(tester, "theProviderOfAnImage");

      expect(tester.widget<Image>(find.byType(Image)).image, isA<StorageManagerImageProvider>());
    });

    testWidgets("paints the image the storage answered with", (tester) async {
      await anImageOf(tester, "theImageOfAFile");
      await theImageIsShown(tester);

      expect(tester.widget<RawImage>(find.byType(RawImage)).image?.width, 8);
    });

    testWidgets("asks the storage for the file it is given", (tester) async {
      await anImageOf(tester, "theFileOfAnImage");
      await theImageIsShown(tester);

      expect(storage.askedFiles, ["theFileOfAnImage"]);
    });

    testWidgets("holds the place of the image while it is being loaded", (tester) async {
      await anImageOf(
        tester,
        "anImageWhichIsLoading",
        placeholderBuilder: (context) => const Text("loading"),
      );

      expect(find.text("loading"), findsOneWidget);
    });

    testWidgets("drops the placeholder once the image is loaded", (tester) async {
      await anImageOf(
        tester,
        "anImageWhichIsLoaded",
        placeholderBuilder: (context) => const Text("loading"),
      );
      await theImageIsShown(tester);

      expect(find.text("loading"), findsNothing);
    });

    testWidgets("shows what the application asks for when the image cannot be loaded", (
      tester,
    ) async {
      storage.fileResult = StorageRequestResult.genericError;

      await anImageOf(
        tester,
        "aFileWhichIsNotThere",
        errorBuilder: (context, error, stackTrace) => const Text("no image"),
      );
      await theImageIsShown(tester);

      expect(find.text("no image"), findsOneWidget);
    });

    testWidgets("keeps the size the application asked for", (tester) async {
      await anImageOf(tester, "anImageOfItsOwnSize");
      await theImageIsShown(tester);

      expect(tester.getSize(find.byType(Image)), const Size(8, 8));
    });
  });
}
