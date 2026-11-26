// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/errors/act_config_load_exception.dart';
import 'package:act_config_manager/src/errors/act_config_mapping_format_exception.dart';
import 'package:act_config_manager/src/models/env_config_mapping_model.dart';
import 'package:act_config_manager/src/types/env_type.dart';
import 'package:act_config_manager/src/utilities/env_config_mapping_utility.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The asset key of the mapping file.
const _mappingPath = "assets/config/env_config_mapping";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(FakeAssets.stop);

  group("EnvConfigMappingUtility.fromAssetBundle", () {
    test("returns no model when the file doesn't exist", () async {
      FakeAssets.serve({});

      final models = await EnvConfigMappingUtility.fromAssetBundle(_mappingPath);

      expect(models, isEmpty);
    });

    test("returns no model when the file is empty", () async {
      FakeAssets.serve({"$_mappingPath.yaml": ""});

      final models = await EnvConfigMappingUtility.fromAssetBundle(_mappingPath);

      expect(models, isEmpty);
    });

    test("keeps the path of the config variable an environment variable replaces", () async {
      FakeAssets.serve({"$_mappingPath.yaml": "logs:\n  level: LOGS_LEVEL"});

      final models = await EnvConfigMappingUtility.fromAssetBundle(_mappingPath);

      expect(models, [
        const EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "level"]),
      ]);
    });

    test("returns one model per mapped config variable", () async {
      FakeAssets.serve({
        "$_mappingPath.yaml": "logs:\n  level: LOGS_LEVEL\n  logsNb: LOGS_NB\nhost: HOST",
      });

      final models = await EnvConfigMappingUtility.fromAssetBundle(_mappingPath);

      expect(models, [
        const EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "level"]),
        const EnvConfigMappingModel(envKey: "LOGS_NB", path: ["logs", "logsNb"]),
        const EnvConfigMappingModel(envKey: "HOST", path: ["host"]),
      ]);
    });

    test("reads the format of a variable which describes one", () async {
      FakeAssets.serve({
        "$_mappingPath.yaml":
            "logs:\n"
            "  enable:\n"
            "    __name: LOGS_ENABLE\n"
            "    __format: boolean\n",
      });

      final models = await EnvConfigMappingUtility.fromAssetBundle(_mappingPath);

      expect(models, [
        const EnvConfigMappingModel(
          envKey: "LOGS_ENABLE",
          path: ["logs", "enable"],
          type: EnvType.bool,
        ),
      ]);
    });

    test("reads a mapping file written in JSON", () async {
      FakeAssets.serve({"$_mappingPath.json": '{"logs": {"level": "LOGS_LEVEL"}}'});

      final models = await EnvConfigMappingUtility.fromAssetBundle(_mappingPath);

      expect(models, [
        const EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "level"]),
      ]);
    });

    test("refuses a mapping file which cannot be parsed", () async {
      FakeAssets.serve({"$_mappingPath.yaml": "logs:\n  - level\n level: LOGS_LEVEL"});

      expect(
        () => EnvConfigMappingUtility.fromAssetBundle(_mappingPath),
        throwsA(isA<ActConfigLoadException>()),
      );
    });

    test("refuses a list of variables", () async {
      FakeAssets.serve({"$_mappingPath.yaml": "logs:\n  - LOGS_LEVEL\n  - LOGS_NB"});

      expect(
        () => EnvConfigMappingUtility.fromAssetBundle(_mappingPath),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("refuses a variable name which is not a string", () async {
      FakeAssets.serve({"$_mappingPath.yaml": "logs:\n  logsNb: 3"});

      expect(
        () => EnvConfigMappingUtility.fromAssetBundle(_mappingPath),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("refuses a detailed variable whose format is unknown", () async {
      FakeAssets.serve({
        "$_mappingPath.yaml":
            "logs:\n"
            "  level:\n"
            "    __name: LOGS_LEVEL\n"
            "    __format: date\n",
      });

      expect(
        () => EnvConfigMappingUtility.fromAssetBundle(_mappingPath),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });
  });
}
