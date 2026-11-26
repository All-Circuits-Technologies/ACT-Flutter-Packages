// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeStorageService service;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    service = FakeStorageService();
  });

  tearDown(() async {
    FakeAssets.stop();
    await globalManager.reset();
  });

  /// Builds the storage manager of an application, with the configuration given.
  Future<FakeStorageManager> aManager([String? storage]) async {
    final config = await (storage == null
        ? FakeStorageConfig.build()
        : FakeStorageConfig.build(storage));
    addTearDown(config.disposeLifeCycle);
    globalManager.managers.registerSingleton<FakeStorageConfig>(config);

    final manager = FakeStorageManager(service);
    await manager.initLifeCycle();

    return manager;
  }

  group("AbsRemoteStorageBuilder", () {
    test("depends on the logger manager", () {
      expect(FakeStorageBuilder(() => FakeStorageManager(service)).dependsOn(), [LoggerManager]);
    });
  });

  group("AbsRemoteStorageManager.getPathSeparator", () {
    test("returns the separator of the configuration", () async {
      final manager = await aManager("storage:\n  pathSeparator: '|'");

      expect(manager.getPathSeparator(), "|");
    });

    test("returns a slash when the configuration says nothing", () async {
      final manager = await aManager();

      expect(manager.getPathSeparator(), "/");
    });
  });

  group("AbsRemoteStorageManager.getFile", () {
    test("asks the storage for the file", () async {
      final manager = await aManager();

      await manager.getFile("aFile");

      expect(service.askedFiles, ["aFile"]);
    });

    test("returns what the storage answers", () async {
      final manager = await aManager();
      service
        ..file = File("aFile")
        ..fileResult = StorageRequestResult.success;

      final answer = await manager.getFile("aFile");

      expect(answer.result, StorageRequestResult.success);
      expect(answer.file?.path, "aFile");
    });

    test("returns the error of the storage", () async {
      final manager = await aManager();
      service.fileResult = StorageRequestResult.accessDenied;

      expect((await manager.getFile("aFile")).result, StorageRequestResult.accessDenied);
    });

    test("goes to the storage when the caller asks for the cache and there is none", () async {
      final manager = await aManager();

      await manager.getFile("aFile");

      expect(service.askedFiles, ["aFile"]);
    });
  });

  group("AbsRemoteStorageManager.clearFileFromCache", () {
    test("does nothing when the application uses no cache", () async {
      final manager = await aManager();

      await expectLater(manager.clearFileFromCache("aFile"), completes);
    });
  });

  group("AbsRemoteStorageManager.listFiles", () {
    test("asks the storage for the path given", () async {
      final manager = await aManager();

      await manager.listFiles("a/path", recursiveSearch: true);

      expect(service.listedPaths.single.searchPath, "a/path");
      expect(service.listedPaths.single.recursiveSearch, isTrue);
    });

    test("returns the page the storage answers with", () async {
      final manager = await aManager();
      service.pages.add((
        result: StorageRequestResult.success,
        page: StoragePage(items: const [StorageFile(path: "a/file")]),
      ));

      final answer = await manager.listFiles("a/path");

      expect(answer.page?.items, const [StorageFile(path: "a/file")]);
    });
  });

  group("AbsRemoteStorageManager.listFilesUntil", () {
    /// Builds the answer of a storage which has one file and, when asked, another page.
    ({StorageRequestResult result, StoragePage? page}) aPage(
      String path, {
      bool hasNextPage = false,
    }) => (
      result: StorageRequestResult.success,
      page: StoragePage(
        items: [StorageFile(path: path)],
        nextPageToken: hasNextPage ? "next" : null,
        hasNextPage: hasNextPage,
      ),
    );

    test("gathers every page when the caller asks for no condition", () async {
      final manager = await aManager();
      service.pages
        ..add(aPage("first", hasNextPage: true))
        ..add(aPage("second"));

      final answer = await manager.listFilesUntil("a/path");

      expect(answer.page?.items.map((file) => file.path), ["first", "second"]);
    });

    test("carries the token of a page over to the next call", () async {
      final manager = await aManager();
      service.pages
        ..add(aPage("first", hasNextPage: true))
        ..add(aPage("second"));

      await manager.listFilesUntil("a/path");

      expect(service.listedPaths.map((call) => call.nextToken), [null, "next"]);
    });

    test("stops on the page which matches what the caller waits for", () async {
      final manager = await aManager();
      service.pages
        ..add(aPage("first", hasNextPage: true))
        ..add(aPage("second", hasNextPage: true));

      final answer = await manager.listFilesUntil(
        "a/path",
        matchUntil: (lastItems) => lastItems.any((file) => file.path == "first"),
      );

      expect(answer.page?.items.map((file) => file.path), ["first"]);
    });

    test("stops on the condition which reads every file gathered so far", () async {
      final manager = await aManager();
      service.pages
        ..add(aPage("first", hasNextPage: true))
        ..add(aPage("second", hasNextPage: true));

      final answer = await manager.listFilesUntil(
        "a/path",
        matchUntilWithAll: (items) => items.length >= 2,
      );

      expect(answer.page?.items.map((file) => file.path), ["first", "second"]);
    });

    test("stops as soon as the storage answers an error", () async {
      final manager = await aManager();
      service.pages
        ..add(aPage("first", hasNextPage: true))
        ..add((result: StorageRequestResult.accessDenied, page: null));

      final answer = await manager.listFilesUntil("a/path");

      expect(answer.result, StorageRequestResult.accessDenied);
      expect(answer.page, isNull);
    });
  });
}
