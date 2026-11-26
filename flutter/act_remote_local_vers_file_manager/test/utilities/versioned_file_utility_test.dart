// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_remote_local_vers_file_manager/src/utilities/versioned_file_utility.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_remote_dir.dart';

void main() {
  late Directory root;
  late FakeExternalLogger logs;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    root = Directory.systemTemp.createTempSync("act_versioned_file_test");
    addTearDown(() => root.deleteSync(recursive: true));
  });

  /// A storage which holds [files], one content per path.
  FakeStorage aStorage(Map<String, String> files) => FakeStorage(root: root, files: files);

  group("VersionedFileUtility.getFileCurrentVersion", () {
    test("reads the version the stamp file names", () async {
      final storage = aStorage({"terms/current.txt": "v2"});

      final result = await VersionedFileUtility.getFileCurrentVersion(
        storage: storage,
        dirId: "terms",
        cacheVersion: false,
        logsHelper: logs.buildHelper(),
      );

      expect(result.requestResult, StorageRequestResult.success);
      expect(result.version, "v2");
    });

    test("reads a version which was written with spaces around it", () async {
      final storage = aStorage({"terms/current.txt": " v2 \n"});

      final result = await VersionedFileUtility.getFileCurrentVersion(
        storage: storage,
        dirId: "terms",
        cacheVersion: false,
        logsHelper: logs.buildHelper(),
      );

      expect(result.version, "v2");
    });

    test("says how the storage failed when the stamp file is not there", () async {
      final storage = aStorage(const {});

      final result = await VersionedFileUtility.getFileCurrentVersion(
        storage: storage,
        dirId: "terms",
        cacheVersion: false,
        logsHelper: logs.buildHelper(),
      );

      expect(result.requestResult, StorageRequestResult.ioError);
      expect(result.version, isNull);
    });

    test("gives up on a stamp file which names no version", () async {
      final storage = aStorage({"terms/current.txt": "  \n"});

      final result = await VersionedFileUtility.getFileCurrentVersion(
        storage: storage,
        dirId: "terms",
        cacheVersion: false,
        logsHelper: logs.buildHelper(),
      );

      expect(result.requestResult, StorageRequestResult.genericError);
      expect(result.version, isNull);
    });

    test("lets the storage keep the stamp file when it is told to", () async {
      final storage = aStorage({"terms/current.txt": "v2"});

      await VersionedFileUtility.getFileCurrentVersion(
        storage: storage,
        dirId: "terms",
        cacheVersion: true,
        logsHelper: logs.buildHelper(),
      );

      expect(storage.requests.single.useCache, isTrue);
    });
  });

  group("VersionedFileUtility.getVersionedFile", () {
    test("reads the version and then the file it names", () async {
      final storage = aStorage({"terms/current.txt": "v2", "terms/v2.md": "the terms"});

      final result = await VersionedFileUtility.getVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(result.result, StorageRequestResult.success);
      expect(result.data?.version, "v2");
      expect(result.data?.filePath, "terms/v2.md");
      expect(await result.data?.file.readAsString(), "the terms");
      expect(storage.askedPaths, ["terms/current.txt", "terms/v2.md"]);
    });

    test("reads the version the caller already knows, and asks for nothing else", () async {
      final storage = aStorage({"terms/current.txt": "v2", "terms/v1.md": "the old terms"});

      final result = await VersionedFileUtility.getVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        versionOverride: "v1",
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(result.data?.version, "v1");
      expect(storage.askedPaths, ["terms/v1.md"]);
    });

    test("gives up when the version cannot be read", () async {
      final storage = aStorage({"terms/v2.md": "the terms"});

      final result = await VersionedFileUtility.getVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(result.result, StorageRequestResult.ioError);
      expect(result.data, isNull);
    });

    test("gives up when the version names a file which is not there", () async {
      final storage = aStorage({"terms/current.txt": "v3"});

      final result = await VersionedFileUtility.getVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(result.result, StorageRequestResult.ioError);
      expect(result.data, isNull);
    });

    test("lets the storage keep the file and not the version", () async {
      final storage = aStorage({"terms/current.txt": "v2", "terms/v2.md": "the terms"});

      await VersionedFileUtility.getVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(storage.requests.first.useCache, isFalse);
      expect(storage.requests.last.useCache, isTrue);
    });
  });
}
