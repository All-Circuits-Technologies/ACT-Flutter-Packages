// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_file_transfer_manager/act_file_transfer_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(FakeGlobalManager.install);

  group("FileSaverBuilder", () {
    test("depends on the logger manager", () {
      expect(const FileSaverBuilder().dependsOn(), [LoggerManager]);
    });

    test("builds a file saver manager", () {
      expect(const FileSaverBuilder().factory(), isA<FileSaverManager>());
    });
  });
}
