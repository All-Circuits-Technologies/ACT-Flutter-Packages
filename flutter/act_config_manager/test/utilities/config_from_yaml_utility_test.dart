// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_config_manager/src/errors/act_config_load_exception.dart';
import 'package:act_config_manager/src/errors/act_config_mapping_format_exception.dart';
import 'package:act_config_manager/src/utilities/config_from_yaml_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The folder the configuration files are read from.
const _configPath = "assets/config/";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(FakeAssets.stop);

  group("ConfigFromYamlUtility.parseFromConfigFiles", () {
    test("returns the values of the default file", () async {
      FakeAssets.serve({"${_configPath}default.yaml": "logs:\n  level: warning"});

      final configs = await ConfigFromYamlUtility.parseFromConfigFiles(
        _configPath,
        Environment.production,
      );

      expect(configs, {
        "logs": {"level": "warning"},
      });
    });

    test("returns an empty configuration when no file exists", () async {
      FakeAssets.serve({});

      final configs = await ConfigFromYamlUtility.parseFromConfigFiles(
        _configPath,
        Environment.production,
      );

      expect(configs, isEmpty);
    });

    test("reads the file of the chosen environment and not the ones of the others", () async {
      FakeAssets.serve({
        "${_configPath}production.yaml": "host: prod.example.com",
        "${_configPath}qualification.yaml": "host: qualif.example.com",
        "${_configPath}development.yaml": "host: dev.example.com",
      });

      final configs = await ConfigFromYamlUtility.parseFromConfigFiles(
        _configPath,
        Environment.qualification,
      );

      expect(configs, {"host": "qualif.example.com"});
    });

    test("lets the file of the environment override the default one", () async {
      FakeAssets.serve({
        "${_configPath}default.yaml": "logs:\n  level: warning\n  logsNb: 3",
        "${_configPath}production.yaml": "logs:\n  level: error",
      });

      final configs = await ConfigFromYamlUtility.parseFromConfigFiles(
        _configPath,
        Environment.production,
      );

      expect(configs, {
        "logs": {"level": "error", "logsNb": 3},
      });
    });

    test("lets the local file override the file of the environment", () async {
      FakeAssets.serve({
        "${_configPath}default.yaml": "logs:\n  level: warning",
        "${_configPath}production.yaml": "logs:\n  level: error",
        "${_configPath}local.yaml": "logs:\n  level: trace",
      });

      final configs = await ConfigFromYamlUtility.parseFromConfigFiles(
        _configPath,
        Environment.production,
      );

      expect(configs, {
        "logs": {"level": "trace"},
      });
    });

    test("merges the files down to the leaves of the configuration", () async {
      FakeAssets.serve({
        "${_configPath}default.yaml": "firebase:\n  crash:\n    enable: false\n    auto: false",
        "${_configPath}local.yaml": "firebase:\n  crash:\n    enable: true",
      });

      final configs = await ConfigFromYamlUtility.parseFromConfigFiles(
        _configPath,
        Environment.development,
      );

      expect(configs, {
        "firebase": {
          "crash": {"enable": true, "auto": false},
        },
      });
    });

    test("reads a JSON file as well as a YAML one", () async {
      FakeAssets.serve({"${_configPath}default.json": '{"logs": {"level": "warning"}}'});

      final configs = await ConfigFromYamlUtility.parseFromConfigFiles(
        _configPath,
        Environment.development,
      );

      expect(configs, {
        "logs": {"level": "warning"},
      });
    });

    test("throws when a file cannot be parsed", () async {
      FakeAssets.serve({"${_configPath}default.yaml": "logs:\n  - level\n level: warning"});

      expect(
        () => ConfigFromYamlUtility.parseFromConfigFiles(_configPath, Environment.development),
        throwsA(isA<ActConfigLoadException>()),
      );
    });

    test("throws when the content of a file is not a map", () async {
      FakeAssets.serve({"${_configPath}default.yaml": "- first\n- second"});

      expect(
        () => ConfigFromYamlUtility.parseFromConfigFiles(_configPath, Environment.development),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("accepts an empty file", () async {
      FakeAssets.serve({"${_configPath}default.yaml": ""});

      final configs = await ConfigFromYamlUtility.parseFromConfigFiles(
        _configPath,
        Environment.development,
      );

      expect(configs, isEmpty);
    });
  });
}
