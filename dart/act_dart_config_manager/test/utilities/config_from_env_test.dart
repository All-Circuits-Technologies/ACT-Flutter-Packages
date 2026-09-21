// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:test/test.dart';

/// Build the mapping models from a yaml [content].
List<EnvConfigMappingModel> _mapping(String content) => EnvConfigMappingParser.fromContent(content);

void main() {
  group("ConfigFromEnv.parse", () {
    test("returns an empty configuration when there is no mapping", () {
      final configs = ConfigFromEnv.parse(
        mapping: const [],
        processEnv: const {},
        dotEnv: const {"LOGS_LEVEL": "warning"},
      );

      expect(configs, isEmpty);
    });

    test("builds the configuration structure the mapping describes", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("logs:\n  console:\n    level: LOGS_LEVEL"),
        processEnv: const {},
        dotEnv: const {"LOGS_LEVEL": "warning"},
      );

      expect(configs, {
        "logs": {
          "console": {"level": "warning"},
        },
      });
    });

    test("puts the variables which share a path in the same map", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("logs:\n  level: LOGS_LEVEL\n  logsNb: LOGS_NB"),
        processEnv: const {},
        dotEnv: const {"LOGS_LEVEL": "warning", "LOGS_NB": "3"},
      );

      expect(configs, {
        "logs": {"level": "warning", "logsNb": "3"},
      });
    });

    test("leaves out the variables which are not set", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("logs:\n  level: LOGS_LEVEL\n  logsNb: A_VARIABLE_WHICH_IS_NOT_SET"),
        processEnv: const {},
        dotEnv: const {"LOGS_LEVEL": "warning"},
      );

      expect(configs, {
        "logs": {"level": "warning"},
      });
    });

    test("keeps a variable of a string format as it is written", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("logs:\n  level:\n    __name: LOGS_LEVEL\n    __format: string\n"),
        processEnv: const {},
        dotEnv: const {"LOGS_LEVEL": "3"},
      );

      expect(configs, {
        "logs": {"level": "3"},
      });
    });

    test("reads a variable of a boolean format as a boolean", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("logs:\n  enable:\n    __name: LOGS_ENABLE\n    __format: boolean\n"),
        processEnv: const {},
        dotEnv: const {"LOGS_ENABLE": "true"},
      );

      expect(configs, {
        "logs": {"enable": true},
      });
    });

    test("reads a variable of a number format as an integer", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("logs:\n  logsNb:\n    __name: LOGS_NB\n    __format: number\n"),
        processEnv: const {},
        dotEnv: const {"LOGS_NB": "3"},
      );

      expect(configs, {
        "logs": {"logsNb": 3},
      });
    });

    test("reads a number which has a decimal separator as a decimal number", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("logs:\n  ratio:\n    __name: LOGS_RATIO\n    __format: number\n"),
        processEnv: const {},
        dotEnv: const {"LOGS_RATIO": "1.5"},
      );

      expect(configs, {
        "logs": {"ratio": 1.5},
      });
    });

    test("reads a variable of a yaml format as a structure", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("logs:\n  appenders:\n    __name: LOGS_APPENDERS\n    __format: yaml\n"),
        processEnv: const {},
        dotEnv: const {"LOGS_APPENDERS": '{"console": true, "file": false}'},
      );

      expect(configs, {
        "logs": {
          "appenders": {"console": true, "file": false},
        },
      });
    });

    test("refuses a variable whose value doesn't match its format", () {
      expect(
        () => ConfigFromEnv.parse(
          mapping: _mapping("logs:\n  logsNb:\n    __name: LOGS_NB\n    __format: number\n"),
          processEnv: const {},
          dotEnv: const {"LOGS_NB": "three"},
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test("reads the variables of the process environment", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("process:\n  variable: A_PROCESS_VARIABLE"),
        processEnv: const {"A_PROCESS_VARIABLE": "from the process"},
      );

      expect(configs, {
        "process": {"variable": "from the process"},
      });
    });

    test("lets the dot env variables override the process ones", () {
      final configs = ConfigFromEnv.parse(
        mapping: _mapping("process:\n  variable: A_PROCESS_VARIABLE"),
        processEnv: const {"A_PROCESS_VARIABLE": "from the process"},
        dotEnv: const {"A_PROCESS_VARIABLE": "from the dot env file"},
      );

      expect(configs, {
        "process": {"variable": "from the dot env file"},
      });
    });
  });
}
