// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("PathUtility.extensionWithoutDot", () {
    test("returns the extension of a file without its dot", () {
      expect(PathUtility.extensionWithoutDot("folder/report.pdf"), "pdf");
    });

    test("returns as many extensions as the level asks for", () {
      expect(PathUtility.extensionWithoutDot("archive.tar.gz"), "gz");
      expect(PathUtility.extensionWithoutDot("archive.tar.gz", 2), "tar.gz");
    });

    test("returns an empty string when the file has no extension", () {
      expect(PathUtility.extensionWithoutDot("folder/report"), "");
    });

    test("returns an empty string when the path is empty", () {
      expect(PathUtility.extensionWithoutDot(""), "");
    });

    test("ignores the dots of the folders of the path", () {
      expect(PathUtility.extensionWithoutDot("my.folder/report"), "");
    });

    test("treats a leading dot as the start of a hidden file and not as an extension", () {
      expect(PathUtility.extensionWithoutDot(".gitignore"), "");
    });
  });
}
