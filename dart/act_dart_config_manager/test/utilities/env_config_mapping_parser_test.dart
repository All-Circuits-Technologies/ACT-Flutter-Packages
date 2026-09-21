// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:test/test.dart';

void main() {
  group("EnvConfigMappingParser.fromContent", () {
    test("returns no model when the content is null", () {
      expect(EnvConfigMappingParser.fromContent(null), isEmpty);
    });

    test("returns no model when the content is empty", () {
      expect(EnvConfigMappingParser.fromContent(""), isEmpty);
    });

    test("keeps the path of the config variable an environment variable replaces", () {
      final models = EnvConfigMappingParser.fromContent("logs:\n  level: LOGS_LEVEL");

      expect(models, [
        const EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "level"]),
      ]);
    });

    test("returns one model per mapped config variable", () {
      final models = EnvConfigMappingParser.fromContent(
        "logs:\n  level: LOGS_LEVEL\n  logsNb: LOGS_NB\nhost: HOST",
      );

      expect(models, [
        const EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "level"]),
        const EnvConfigMappingModel(envKey: "LOGS_NB", path: ["logs", "logsNb"]),
        const EnvConfigMappingModel(envKey: "HOST", path: ["host"]),
      ]);
    });

    test("reads the format of a variable which describes one", () {
      final models = EnvConfigMappingParser.fromContent(
        "logs:\n"
        "  enable:\n"
        "    __name: LOGS_ENABLE\n"
        "    __format: boolean\n",
      );

      expect(models, [
        const EnvConfigMappingModel(
          envKey: "LOGS_ENABLE",
          path: ["logs", "enable"],
          type: EnvType.bool,
        ),
      ]);
    });

    test("reads a mapping written in JSON", () {
      final models = EnvConfigMappingParser.fromContent('{"logs": {"level": "LOGS_LEVEL"}}');

      expect(models, [
        const EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "level"]),
      ]);
    });

    test("refuses a mapping which cannot be parsed", () {
      expect(
        () => EnvConfigMappingParser.fromContent("logs:\n  - level\n level: LOGS_LEVEL"),
        throwsA(isA<ActConfigLoadException>()),
      );
    });

    test("refuses a list of variables", () {
      expect(
        () => EnvConfigMappingParser.fromContent("logs:\n  - LOGS_LEVEL\n  - LOGS_NB"),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("refuses a variable name which is not a string", () {
      expect(
        () => EnvConfigMappingParser.fromContent("logs:\n  logsNb: 3"),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("refuses a detailed variable whose format is unknown", () {
      expect(
        () => EnvConfigMappingParser.fromContent(
          "logs:\n"
          "  level:\n"
          "    __name: LOGS_LEVEL\n"
          "    __format: date\n",
        ),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });
  });
}
