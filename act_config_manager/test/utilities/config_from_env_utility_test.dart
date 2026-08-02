// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/utilities/config_from_env_utility.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

/// The folder the configuration files are read from.
const _configPath = "assets/config/";

/// The asset key of the mapping file.
const _mappingKey = "${_configPath}env_config_mapping.yaml";

/// The asset key of the dot env file.
const _dotEnvKey = "$_configPath.env";

/// A variable of the environment of the running process, and its value.
///
/// The tests cannot add a variable to the environment of their own process, so the ones which need
/// a variable coming from the operating system use one which is already there.
MapEntry<String, String> _aPlatformVariable() =>
    ActPlatform.instance.environment.entries.firstWhere((entry) => entry.value.isNotEmpty);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    FakeAssets.stop();
    dotenv.clean();
  });

  group("ConfigFromEnvUtility.parseFromEnv", () {
    test("returns an empty configuration when there is no mapping file", () async {
      FakeAssets.serve({_dotEnvKey: "LOGS_LEVEL=warning"});

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, isEmpty);
    });

    test("builds the configuration structure the mapping file describes", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  console:\n    level: LOGS_LEVEL",
        _dotEnvKey: "LOGS_LEVEL=warning",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {
          "console": {"level": "warning"},
        },
      });
    });

    test("puts the variables which share a path in the same map", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  level: LOGS_LEVEL\n  logsNb: LOGS_NB",
        _dotEnvKey: "LOGS_LEVEL=warning\nLOGS_NB=3",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {"level": "warning", "logsNb": "3"},
      });
    });

    test("leaves out the variables which are not set", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  level: LOGS_LEVEL\n  logsNb: A_VARIABLE_WHICH_IS_NOT_SET",
        _dotEnvKey: "LOGS_LEVEL=warning",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {"level": "warning"},
      });
    });

    test("keeps a variable of a string format as it is written", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  level:\n    __name: LOGS_LEVEL\n    __format: string\n",
        _dotEnvKey: "LOGS_LEVEL=3",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {"level": "3"},
      });
    });

    test("reads a variable of a boolean format as a boolean", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  enable:\n    __name: LOGS_ENABLE\n    __format: boolean\n",
        _dotEnvKey: "LOGS_ENABLE=true",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {"enable": true},
      });
    });

    test("reads a variable of a number format as an integer", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  logsNb:\n    __name: LOGS_NB\n    __format: number\n",
        _dotEnvKey: "LOGS_NB=3",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {"logsNb": 3},
      });
    });

    test("reads a number which has a decimal separator as a decimal number", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  ratio:\n    __name: LOGS_RATIO\n    __format: number\n",
        _dotEnvKey: "LOGS_RATIO=1.5",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {"ratio": 1.5},
      });
    });

    test("reads a variable of a yaml format as a structure", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  appenders:\n    __name: LOGS_APPENDERS\n    __format: yaml\n",
        _dotEnvKey: 'LOGS_APPENDERS={"console": true, "file": false}',
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {
          "appenders": {"console": true, "file": false},
        },
      });
    });

    test("refuses a variable whose value doesn't match its format", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  logsNb:\n    __name: LOGS_NB\n    __format: number\n",
        _dotEnvKey: "LOGS_NB=three",
      });

      expect(() => ConfigFromEnvUtility.parseFromEnv(_configPath), throwsA(isA<FormatException>()));
    });

    test("reads the variables of the environment of the process", () async {
      final platformVariable = _aPlatformVariable();
      FakeAssets.serve({_mappingKey: "process:\n  variable: ${platformVariable.key}"});

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "process": {"variable": platformVariable.value},
      });
    });

    test("lets the dot env file override the environment of the process", () async {
      final platformVariable = _aPlatformVariable();
      FakeAssets.serve({
        _mappingKey: "process:\n  variable: ${platformVariable.key}",
        _dotEnvKey: "${platformVariable.key}=from the dot env file",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "process": {"variable": "from the dot env file"},
      });
    });

    test("accepts an empty dot env file", () async {
      FakeAssets.serve({_mappingKey: "logs:\n  level: LOGS_LEVEL", _dotEnvKey: ""});

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, isEmpty);
    });

    test("ignores the comments and the empty lines of the dot env file", () async {
      FakeAssets.serve({
        _mappingKey: "logs:\n  level: LOGS_LEVEL",
        _dotEnvKey: "# The level of the logs\n\nLOGS_LEVEL=warning\n",
      });

      final configs = await ConfigFromEnvUtility.parseFromEnv(_configPath);

      expect(configs, {
        "logs": {"level": "warning"},
      });
    });
  });
}
