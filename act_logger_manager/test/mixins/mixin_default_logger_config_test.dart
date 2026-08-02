// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_logger_config_manager.dart';

void main() {
  group("MixinDefaultLoggerConfig", () {
    test("gathers the variables of the manager and of the console logger", () {
      final config = FakeLoggerConfigManager();

      expect(config, isA<MixinLoggerConfig>());
      expect(config, isA<MixinCslLoggerConfig>());
      expect(config, isA<MixinDefaultLoggerConfig>());
    });
  });
}
