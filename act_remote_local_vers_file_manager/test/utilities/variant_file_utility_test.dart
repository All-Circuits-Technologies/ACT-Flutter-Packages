// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_remote_local_vers_file_manager/src/utilities/variant_file_utility.dart';
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
    root = Directory.systemTemp.createTempSync("act_variant_file_test");
    addTearDown(() => root.deleteSync(recursive: true));
  });

  /// Searches for a file which is named after one of [variants], in a storage holding [files].
  Future<({StorageRequestResult result, ({String variant, String filePath, File file})? data})>
  aSearch({
    required Map<String, String> files,
    List<String> variants = const ["fr_fr", "en_gb"],
    FakeStorage? storage,
  }) => VariantFileUtility.getVariantFile(
    storage: storage ?? FakeStorage(root: root, files: files),
    variants: variants,
    variantToFilePath: (variant) => "terms/$variant/terms.md",
    useCache: false,
    logsHelper: logs.buildHelper(),
  );

  group("VariantFileUtility.getVariantFile", () {
    test("answers the file of the first variant which has one", () async {
      final result = await aSearch(files: {"terms/fr_fr/terms.md": "les conditions"});

      expect(result.result, StorageRequestResult.success);
      expect(result.data?.variant, "fr_fr");
      expect(result.data?.filePath, "terms/fr_fr/terms.md");
      expect(await result.data?.file.readAsString(), "les conditions");
    });

    test("falls back to the next variant when the first has no file", () async {
      final storage = FakeStorage(root: root, files: {"terms/en_gb/terms.md": "the terms"});

      final result = await aSearch(files: const {}, storage: storage);

      expect(result.data?.variant, "en_gb");
      expect(storage.askedPaths, ["terms/fr_fr/terms.md", "terms/en_gb/terms.md"]);
    });

    test("stops asking the storage as soon as a variant answered", () async {
      final storage = FakeStorage(root: root, files: {"terms/fr_fr/terms.md": "les conditions"});

      await aSearch(files: const {}, storage: storage);

      expect(storage.askedPaths, ["terms/fr_fr/terms.md"]);
    });

    test("answers how the storage failed on the variant which was tried first", () async {
      final storage = FakeStorage(root: root)..missingFileResult = StorageRequestResult.accessDenied;

      final result = await aSearch(files: const {}, storage: storage);

      expect(result.result, StorageRequestResult.accessDenied);
      expect(result.data, isNull);
      expect(logs.recordsAtLevel(LogsLevel.warn), isNotEmpty);
    });

    test("answers an error when it was given no variant to try", () async {
      final result = await aSearch(files: const {}, variants: const []);

      expect(result.result, StorageRequestResult.genericError);
      expect(result.data, isNull);
    });
  });
}
