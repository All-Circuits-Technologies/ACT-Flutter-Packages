// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:ui';

import 'package:act_remote_local_vers_file_manager/src/utilities/localized_file_utility.dart';
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
    root = Directory.systemTemp.createTempSync("act_localized_file_test");
    addTearDown(() => root.deleteSync(recursive: true));
  });

  /// Searches for the localized file of an application whose storage holds [files].
  Future<({StorageRequestResult result, ({Locale locale, String filePath, File file})? data})>
  aSearch(
    FakeStorage storage, {
    List<Locale> locales = const [Locale("fr", "FR"), Locale("en", "GB")],
  }) => LocalizedFileUtility.getLocalizedFile(
    storage: storage,
    dirId: "terms",
    fileName: "terms.md",
    locales: locales,
    useCache: false,
    logsHelper: logs.buildHelper(),
  );

  group("LocalizedFileUtility.getLocalizedFile", () {
    test("answers the file of the locale the application is shown in", () async {
      final storage = FakeStorage(
        root: root,
        files: {"terms/fr_fr/terms.md": "les conditions", "terms/en_gb/terms.md": "the terms"},
      );

      final result = await aSearch(storage);

      expect(result.result, StorageRequestResult.success);
      expect(result.data?.locale, const Locale("fr", "FR"));
      expect(await result.data?.file.readAsString(), "les conditions");
    });

    test("falls back to the language of a locale whose country has no file", () async {
      final storage = FakeStorage(root: root, files: {"terms/fr/terms.md": "les conditions"});

      final result = await aSearch(storage);

      expect(result.data?.locale, const Locale("fr"));
      expect(storage.askedPaths.take(2), ["terms/fr_fr/terms.md", "terms/fr/terms.md"]);
    });

    test("falls back to the locale the application defaults to", () async {
      final storage = FakeStorage(root: root, files: {"terms/en_gb/terms.md": "the terms"});

      final result = await aSearch(storage);

      expect(result.data?.locale, const Locale("en", "GB"));
      expect(await result.data?.file.readAsString(), "the terms");
    });

    test("answers how the storage failed when no locale has a file", () async {
      final storage = FakeStorage(root: root)..missingFileResult = StorageRequestResult.accessDenied;

      final result = await aSearch(storage);

      expect(result.result, StorageRequestResult.accessDenied);
      expect(result.data, isNull);
    });
  });
}
