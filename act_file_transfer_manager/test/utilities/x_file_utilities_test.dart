// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:typed_data';

import 'package:act_file_transfer_manager/act_file_transfer_manager.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("XFileUtilities.getBinaryFileContent", () {
    test("returns the content of the file", () async {
      final file = XFile.fromData(Uint8List.fromList("the content".codeUnits), name: "a.txt");

      final bytes = await XFileUtilities.getBinaryFileContent(xFile: file);

      expect(String.fromCharCodes(bytes!), "the content");
    });

    test("returns an empty content for a file which holds nothing", () async {
      final file = XFile.fromData(Uint8List(0), name: "a.txt");

      expect(await XFileUtilities.getBinaryFileContent(xFile: file), isEmpty);
    });

    test("returns null for a file which is not there", () async {
      final file = XFile("a/file/which/does/not/exist.txt");

      expect(await XFileUtilities.getBinaryFileContent(xFile: file), isNull);
    });

    test("reports the file it cannot read", () async {
      await XFileUtilities.getBinaryFileContent(
        xFile: XFile("a/file/which/does/not/exist.txt"),
      );

      expect(logger.recordsAtLevel(LogsLevel.error).length, 1);
    });
  });
}
