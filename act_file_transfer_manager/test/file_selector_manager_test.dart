// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_file_transfer_manager/act_file_transfer_manager.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_file_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLogger logger;
  late FakeFileSelector selector;
  const manager = FileSelectorManager();

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
    selector = FakeFileSelector();
    FileSelectorPlatform.instance = selector;
  });

  /// Builds the file a user picks, whose content is [content].
  ///
  /// The name of a file is read from its path, so the path is what the test names.
  XFile aFile(String name, [String content = "a content"]) =>
      XFile.fromData(Uint8List.fromList(content.codeUnits), path: name);

  group("FileSelectorBuilder", () {
    test("depends on no other manager", () {
      expect(const FileSelectorBuilder().dependsOn(), isEmpty);
    });
  });

  group("FileSelectorManager.openSelector", () {
    test("returns the file the user picks", () async {
      final file = aFile("archive.zip");
      selector.picked = file;

      final result = await manager.openSelector(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.success);
      expect(result.value, same(file));
    });

    test("tells the dialog which files the application accepts", () async {
      await manager.openSelector(
        allowedExtensions: const [FileExtensions.zip, FileExtensions.tar],
        label: "archives",
      );

      expect(selector.acceptedTypeGroups.single.label, "archives");
      expect(selector.acceptedTypeGroups.single.extensions, const ["zip", "tar"]);
    });

    test("returns no file when the user closes the dialog without picking one", () async {
      final result = await manager.openSelector(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.success);
      expect(result.value, isNull);
    });

    test("reports an error when the dialog cannot be opened", () async {
      selector.fails = true;

      final result = await manager.openSelector(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.error);
      expect(logger.recordsAtLevel(LogsLevel.error).length, 1);
    });

    test("refuses a file whose extension is not one of the allowed ones", () async {
      selector.picked = aFile("notes.txt");

      final result = await manager.openSelector(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.error);
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("accepts a file of any extension when the caller does not insist", () async {
      final file = aFile("notes.txt");
      selector.picked = file;

      final result = await manager.openSelector(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
        strictOnExtensions: false,
      );

      expect(result.value, same(file));
    });

    test("reads the extension of a file whose name holds several dots", () async {
      selector.picked = aFile("an.archive.tar.gz");

      final result = await manager.openSelector(
        allowedExtensions: const [FileExtensions.gz],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.success);
    });
  });

  group("FileSelectorManager.openSelectorAndGetBytes", () {
    test("returns the content of the file the user picks", () async {
      selector.picked = aFile("archive.zip", "the content");

      final result = await manager.openSelectorAndGetBytes(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.success);
      expect(String.fromCharCodes(result.value!), "the content");
    });

    test("returns nothing when the user closes the dialog without picking a file", () async {
      final result = await manager.openSelectorAndGetBytes(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.success);
      expect(result.value, isNull);
    });

    test("reports the error of the dialog", () async {
      selector.fails = true;

      final result = await manager.openSelectorAndGetBytes(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.error);
    });

    test("reports the file which was picked but cannot be read", () async {
      selector.picked = XFile("a/file/which/does/not/exist.zip");

      final result = await manager.openSelectorAndGetBytes(
        allowedExtensions: const [FileExtensions.zip],
        label: "archives",
      );

      expect(result.status, BoolResultStatus.error);
    });
  });
}
