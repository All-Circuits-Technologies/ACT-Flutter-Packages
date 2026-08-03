// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:ui';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_remote_local_vers_file_manager/act_remote_local_vers_file_manager.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_remote_dir.dart';

/// The files of a folder which holds one version per locale.
const _files = {
  "terms/fr_fr/current.txt": "v2",
  "terms/fr_fr/v2.md": "les conditions",
  "terms/en_gb/current.txt": "v3",
  "terms/en_gb/v3.md": "the terms",
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late FakeStorage storage;

  setUp(() {
    FakeGlobalManager.install();
    root = Directory.systemTemp.createTempSync("act_remote_local_vers_file_test");
    addTearDown(() => root.deleteSync(recursive: true));
  });

  tearDown(FakeAssets.stop);

  /// The manager of an application whose storage holds [files].
  ///
  /// The configuration of the application says [config], which is the json object of the
  /// `remoteLocalVersFile.config` key, and the application overrides it with [overrides].
  Future<FakeDirManager> aManager({
    Map<String, String> files = _files,
    String? config,
    Map<FakeDirType, RemoteLocalDirOptions> overrides = const {},
  }) async {
    final configLine = config == null ? "" : "remoteLocalVersFile:\n  config: $config";
    FakeAssets.serve({"assets/config/default.yaml": configLine});

    final configManager = FakeDirConfig();
    await configManager.initLifeCycle();
    addTearDown(configManager.disposeLifeCycle);

    storage = FakeStorage(root: root, files: files);

    final manager = FakeDirManager(
      storage: storage,
      configManagerGetter: () => configManager,
      overrides: overrides,
    );
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("AbsRemoteLocalVersFileBuilder", () {
    test("depends on the logger and on the configuration of the application", () {
      final builder = FakeDirBuilder(
        () => FakeDirManager(
          storage: FakeStorage(root: root),
          configManagerGetter: FakeDirConfig.new,
        ),
      );

      expect(builder.dependsOn(), [LoggerManager, MixinRemoteLocalVersFileConfig<FakeDirType>]);
    });
  });

  group("AbsRemoteLocalVersFileManager.getLocalizedFile", () {
    test("reads the file of the locale the application is shown in", () async {
      final manager = await aManager(files: {"terms/fr_fr/terms.md": "les conditions"});

      final result = await manager.getLocalizedFile(
        dirType: FakeDirType.terms,
        fileName: "terms.md",
      );

      expect(result.result, StorageRequestResult.success);
      expect(result.data?.locale, const Locale("fr", "FR"));
    });

    test("reads the file of the locales the caller asked for", () async {
      final manager = await aManager(files: {"terms/de_de/terms.md": "die Bedingungen"});

      final result = await manager.getLocalizedFile(
        dirType: FakeDirType.terms,
        fileName: "terms.md",
        locales: const [Locale("de", "DE")],
      );

      expect(result.data?.locale, const Locale("de", "DE"));
    });

    test("reads the file of the locales the configuration of the folder names", () async {
      final manager = await aManager(
        files: {"terms/de_de/terms.md": "die Bedingungen"},
        config: '{ "terms": { "locales": ["de_DE"] } }',
      );

      final result = await manager.getLocalizedFile(
        dirType: FakeDirType.terms,
        fileName: "terms.md",
      );

      expect(result.data?.locale, const Locale("de", "DE"));
    });

    test("lets the storage keep the file it read", () async {
      final manager = await aManager(files: {"terms/fr_fr/terms.md": "les conditions"});

      await manager.getLocalizedFile(dirType: FakeDirType.terms, fileName: "terms.md");

      expect(storage.requests.single.useCache, isTrue);
    });

    test("asks the storage not to keep the file when the caller says so", () async {
      final manager = await aManager(files: {"terms/fr_fr/terms.md": "les conditions"});

      await manager.getLocalizedFile(
        dirType: FakeDirType.terms,
        fileName: "terms.md",
        useCache: false,
      );

      expect(storage.requests.single.useCache, isFalse);
    });
  });

  group("AbsRemoteLocalVersFileManager.getVersionedFile", () {
    test("reads the file of the version the folder is on", () async {
      final manager = await aManager(
        files: {"terms/current.txt": "v2", "terms/v2": "the terms"},
      );

      final result = await manager.getVersionedFile(dirType: FakeDirType.terms);

      expect(result.data?.version, "v2");
      expect(result.data?.filePath, "terms/v2");
    });

    test("names the file of a version the way the caller asks", () async {
      final manager = await aManager(
        files: {"terms/current.txt": "v2", "terms/v2.md": "the terms"},
      );

      final result = await manager.getVersionedFile(
        dirType: FakeDirType.terms,
        versionToFileName: (version) => "$version.md",
      );

      expect(result.data?.filePath, "terms/v2.md");
    });

    test("names the file of a version the way the application decided", () async {
      final manager = await aManager(
        files: {"terms/current.txt": "v2", "terms/v2.md": "the terms"},
        overrides: {
          FakeDirType.terms: RemoteLocalDirOptions(versionToFileName: (version) => "$version.md"),
        },
      );

      final result = await manager.getVersionedFile(dirType: FakeDirType.terms);

      expect(result.data?.filePath, "terms/v2.md");
    });

    test("asks the storage not to keep the version and to keep the file", () async {
      final manager = await aManager(
        files: {"terms/current.txt": "v2", "terms/v2": "the terms"},
      );

      await manager.getVersionedFile(dirType: FakeDirType.terms);

      expect(storage.requests.first.useCache, isFalse);
      expect(storage.requests.last.useCache, isTrue);
    });

    test("keeps the version when the configuration of the folder says so", () async {
      final manager = await aManager(
        files: {"terms/current.txt": "v2", "terms/v2": "the terms"},
        config: '{ "terms": { "cacheVersion": true } }',
      );

      await manager.getVersionedFile(dirType: FakeDirType.terms);

      expect(storage.requests.first.useCache, isTrue);
    });
  });

  group("AbsRemoteLocalVersFileManager.getFileCurrentVersion", () {
    test("reads the version the folder is on", () async {
      final manager = await aManager(files: {"terms/current.txt": "v2"});

      final result = await manager.getFileCurrentVersion(dirType: FakeDirType.terms);

      expect(result.requestResult, StorageRequestResult.success);
      expect(result.version, "v2");
    });

    test("reads the version of the folder of the type it was asked for", () async {
      final manager = await aManager(
        files: {"terms/current.txt": "v2", "release_notes/current.txt": "v7"},
      );

      final result = await manager.getFileCurrentVersion(dirType: FakeDirType.releaseNotes);

      expect(result.version, "v7");
    });
  });

  group("AbsRemoteLocalVersFileManager.getLocalizedVersionedFile", () {
    test("reads the file of the version of the locale of the application", () async {
      final manager = await aManager();

      final result = await manager.getLocalizedVersionedFile(
        dirType: FakeDirType.terms,
        versionToFileName: (version) => "$version.md",
      );

      expect(result.data?.locale, const Locale("fr", "FR"));
      expect(result.data?.version, "v2");
      expect(await result.data?.file.readAsString(), "les conditions");
    });

    test("reads the file of the version the caller asked for", () async {
      final manager = await aManager(files: {..._files, "terms/fr_fr/v1.md": "les anciennes"});

      final result = await manager.getLocalizedVersionedFile(
        dirType: FakeDirType.terms,
        versionToFileName: (version) => "$version.md",
        explicitVersion: "v1",
      );

      expect(result.data?.version, "v1");
    });
  });

  group("AbsRemoteLocalVersFileManager.getFileLocalizedCurrentVersion", () {
    test("reads the version of the locale the application is shown in", () async {
      final manager = await aManager();

      final result = await manager.getFileLocalizedCurrentVersion(dirType: FakeDirType.terms);

      expect(result.data?.locale, const Locale("fr", "FR"));
      expect(result.data?.version, "v2");
    });
  });

  group("AbsRemoteLocalVersFileManager.getOptionsOverrides", () {
    test("takes the options of the application over the ones of the configuration", () async {
      final manager = await aManager(
        files: {"terms/de_de/terms.md": "die Bedingungen"},
        config: '{ "terms": { "locales": ["fr_FR"] } }',
        overrides: {
          FakeDirType.terms: const RemoteLocalDirOptions(locales: [Locale("de", "DE")]),
        },
      );

      final result = await manager.getLocalizedFile(
        dirType: FakeDirType.terms,
        fileName: "terms.md",
      );

      expect(result.data?.locale, const Locale("de", "DE"));
    });

    test("keeps the options of the configuration the application says nothing about", () async {
      final manager = await aManager(
        files: {"terms/current.txt": "v2", "terms/v2.md": "the terms"},
        config: '{ "terms": { "cacheVersion": true } }',
        overrides: {
          FakeDirType.terms: RemoteLocalDirOptions(versionToFileName: (version) => "$version.md"),
        },
      );

      final result = await manager.getVersionedFile(dirType: FakeDirType.terms);

      expect(result.data?.filePath, "terms/v2.md");
      expect(storage.requests.first.useCache, isTrue);
    });

    test("reads the folders the configuration says nothing about", () async {
      final manager = await aManager(
        files: {"release_notes/current.txt": "v7"},
        config: '{ "terms": { "cacheVersion": true } }',
      );

      final result = await manager.getFileCurrentVersion(dirType: FakeDirType.releaseNotes);

      expect(result.version, "v7");
    });
  });
}
