// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_file_transfer_manager/act_file_transfer_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FileExtensions", () {
    test("names the extensions without the dot which precedes them", () {
      expect(
        [
          FileExtensions.zip,
          FileExtensions.csv,
          FileExtensions.json,
          FileExtensions.xml,
          FileExtensions.raucBinary,
          FileExtensions.tar,
          FileExtensions.gz,
          FileExtensions.tgz,
        ],
        everyElement(isNot(startsWith("."))),
      );
    });

    test("builds the extension of a compressed archive from the two it is made of", () {
      expect(FileExtensions.tarGz, "${FileExtensions.tar}.${FileExtensions.gz}");
    });
  });

  group("FileExtensions.getFileExtensionWithDot", () {
    test("puts a dot before the extension", () {
      expect(FileExtensions.getFileExtensionWithDot(FileExtensions.zip), ".zip");
    });

    test("puts a single dot before an extension made of two", () {
      expect(FileExtensions.getFileExtensionWithDot(FileExtensions.tarGz), ".tar.gz");
    });
  });
}
