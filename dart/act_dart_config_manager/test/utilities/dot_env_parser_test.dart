// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:test/test.dart';

void main() {
  group("DotEnvParser.parse", () {
    test("returns no variable for an empty content", () {
      expect(DotEnvParser.parse(""), isEmpty);
    });

    test("reads a name and value pair", () {
      expect(DotEnvParser.parse("LOGS_LEVEL=warning"), {"LOGS_LEVEL": "warning"});
    });

    test("reads several variables", () {
      expect(DotEnvParser.parse("LOGS_LEVEL=warning\nLOGS_NB=3"), {
        "LOGS_LEVEL": "warning",
        "LOGS_NB": "3",
      });
    });

    test("ignores the comments and the empty lines", () {
      expect(DotEnvParser.parse("# The level of the logs\n\nLOGS_LEVEL=warning\n"), {
        "LOGS_LEVEL": "warning",
      });
    });

    test("trims the spaces around the name and the value", () {
      expect(DotEnvParser.parse("  LOGS_LEVEL = warning  "), {"LOGS_LEVEL": "warning"});
    });

    test("reads a variable which the export keyword prefixes", () {
      expect(DotEnvParser.parse("export LOGS_LEVEL=warning"), {"LOGS_LEVEL": "warning"});
    });

    test("removes the surrounding double quotes of a value", () {
      expect(DotEnvParser.parse('LOGS_LEVEL="warning"'), {"LOGS_LEVEL": "warning"});
    });

    test("removes the surrounding single quotes of a value", () {
      expect(DotEnvParser.parse("LOGS_LEVEL='warning'"), {"LOGS_LEVEL": "warning"});
    });

    test("keeps the value characters which follow the first separator", () {
      expect(DotEnvParser.parse("URL=https://example.com/?a=1"), {
        "URL": "https://example.com/?a=1",
      });
    });

    test("ignores a line which has no name", () {
      expect(DotEnvParser.parse("=warning"), isEmpty);
    });

    test("lets a later line override an earlier one", () {
      expect(DotEnvParser.parse("LOGS_LEVEL=warning\nLOGS_LEVEL=error"), {"LOGS_LEVEL": "error"});
    });
  });
}
