// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_logger_manager/src/types/safe_external_loggers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("SafeExternalLoggers.toExternalLoggersMap", () {
    test("builds one logger per value of the enum", () {
      final loggers = SafeExternalLoggers.toExternalLoggersMap();

      expect(loggers.keys, SafeExternalLoggers.values);
    });

    test("builds a logger which writes to the console", () {
      final loggers = SafeExternalLoggers.toExternalLoggersMap();

      expect(loggers[SafeExternalLoggers.console], isA<ConsoleExternalLogger>());
    });

    test("builds a new logger at every call", () {
      final first = SafeExternalLoggers.toExternalLoggersMap();
      final second = SafeExternalLoggers.toExternalLoggersMap();

      expect(
        second[SafeExternalLoggers.console],
        isNot(same(first[SafeExternalLoggers.console])),
      );
    });
  });
}
