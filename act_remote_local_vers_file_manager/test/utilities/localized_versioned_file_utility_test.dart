// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:ui';

import 'package:act_remote_local_vers_file_manager/src/utilities/localized_versioned_file_utility.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_remote_dir.dart';

/// The locales an application under test reads its files in.
const _locales = [Locale("fr", "FR"), Locale("en", "GB")];

/// The files of a folder which holds one version per locale.
const _files = {
  "terms/fr_fr/current.txt": "v2",
  "terms/fr_fr/v2.md": "les conditions",
  "terms/en_gb/current.txt": "v3",
  "terms/en_gb/v3.md": "the terms",
};

void main() {
  late Directory root;
  late FakeExternalLogger logs;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    root = Directory.systemTemp.createTempSync("act_localized_versioned_file_test");
    addTearDown(() => root.deleteSync(recursive: true));
  });

  group("LocalizedVersionedFileUtility.getFileLocalizedCurrentVersion", () {
    test("reads the version of the locale the application is shown in", () async {
      final storage = FakeStorage(root: root, files: _files);

      final result = await LocalizedVersionedFileUtility.getFileLocalizedCurrentVersion(
        storage: storage,
        dirId: "terms",
        locales: _locales,
        cacheVersion: false,
        logsHelper: logs.buildHelper(),
      );

      expect(result.result, StorageRequestResult.success);
      expect(result.data?.locale, const Locale("fr", "FR"));
      expect(result.data?.version, "v2");
    });

    test("reads the version of the locale the application falls back to", () async {
      final storage = FakeStorage(
        root: root,
        files: {"terms/en_gb/current.txt": "v3", "terms/en_gb/v3.md": "the terms"},
      );

      final result = await LocalizedVersionedFileUtility.getFileLocalizedCurrentVersion(
        storage: storage,
        dirId: "terms",
        locales: _locales,
        cacheVersion: false,
        logsHelper: logs.buildHelper(),
      );

      expect(result.data?.locale, const Locale("en", "GB"));
      expect(result.data?.version, "v3");
    });

    test("says how the storage failed when no locale has a version", () async {
      final storage = FakeStorage(root: root);

      final result = await LocalizedVersionedFileUtility.getFileLocalizedCurrentVersion(
        storage: storage,
        dirId: "terms",
        locales: _locales,
        cacheVersion: false,
        logsHelper: logs.buildHelper(),
      );

      expect(result.result, StorageRequestResult.ioError);
      expect(result.data, isNull);
    });
  });

  group("LocalizedVersionedFileUtility.getLocalizedVersionedFile", () {
    test("reads the file of the version of the locale of the application", () async {
      final storage = FakeStorage(root: root, files: _files);

      final result = await LocalizedVersionedFileUtility.getLocalizedVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        locales: _locales,
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(result.result, StorageRequestResult.success);
      expect(result.data?.locale, const Locale("fr", "FR"));
      expect(result.data?.version, "v2");
      expect(result.data?.filePath, "terms/fr_fr/v2.md");
      expect(await result.data?.file.readAsString(), "les conditions");
    });

    test("reads the version the caller asked for rather than the current one", () async {
      final storage = FakeStorage(
        root: root,
        files: {..._files, "terms/fr_fr/v1.md": "les anciennes conditions"},
      );

      final result = await LocalizedVersionedFileUtility.getLocalizedVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        locales: _locales,
        explicitVersion: "v1",
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(result.data?.version, "v1");
      expect(await result.data?.file.readAsString(), "les anciennes conditions");
    });

    test("reads the stamp file of a locale once, whatever the version it reads", () async {
      final storage = FakeStorage(root: root, files: _files);

      await LocalizedVersionedFileUtility.getLocalizedVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        locales: _locales,
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(storage.askedPaths, ["terms/fr_fr/current.txt", "terms/fr_fr/v2.md"]);
    });

    test("gives up when the version of no locale can be read", () async {
      final storage = FakeStorage(root: root);

      final result = await LocalizedVersionedFileUtility.getLocalizedVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        locales: _locales,
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(result.result, StorageRequestResult.ioError);
      expect(result.data, isNull);
    });

    test("gives up when the version names a file which is not there", () async {
      final storage = FakeStorage(root: root, files: {"terms/fr_fr/current.txt": "v9"});

      final result = await LocalizedVersionedFileUtility.getLocalizedVersionedFile(
        storage: storage,
        dirId: "terms",
        versionToFileName: (version) => "$version.md",
        locales: _locales,
        cacheVersion: false,
        cacheFile: true,
        logsHelper: logs.buildHelper(),
      );

      expect(result.result, StorageRequestResult.ioError);
      expect(result.data, isNull);
    });
  });
}
