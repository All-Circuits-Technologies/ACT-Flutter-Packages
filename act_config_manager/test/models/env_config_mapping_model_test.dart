// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/errors/act_config_mapping_format_exception.dart';
import 'package:act_config_manager/src/models/env_config_mapping_model.dart';
import 'package:act_config_manager/src/types/env_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("EnvConfigMappingModel.fromJson", () {
    test("maps a string value to the name of an environment variable", () {
      final model = EnvConfigMappingModel.fromJson(["logs", "level"], "LOGS_LEVEL");

      expect(model.envKey, "LOGS_LEVEL");
      expect(model.path, ["logs", "level"]);
    });

    test("considers a variable a string when the mapping gives no format", () {
      final model = EnvConfigMappingModel.fromJson(["logs", "level"], "LOGS_LEVEL");

      expect(model.type, EnvType.string);
    });

    test("reads the name and the format of a detailed value", () {
      final model = EnvConfigMappingModel.fromJson(
        ["logs", "enable"],
        {"__name": "LOGS_ENABLE", "__format": "boolean"},
      );

      expect(model.envKey, "LOGS_ENABLE");
      expect(model.type, EnvType.bool);
      expect(model.path, ["logs", "enable"]);
    });

    test("refuses a detailed value which has no name", () {
      expect(
        () => EnvConfigMappingModel.fromJson(["logs"], {"__format": "boolean"}),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("refuses a detailed value which has no format", () {
      expect(
        () => EnvConfigMappingModel.fromJson(["logs"], {"__name": "LOGS_ENABLE"}),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("refuses a detailed value whose name is not a string", () {
      expect(
        () => EnvConfigMappingModel.fromJson(["logs"], {"__name": 3, "__format": "number"}),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("refuses a format which is not a known one", () {
      expect(
        () =>
            EnvConfigMappingModel.fromJson(["logs"], {"__name": "LOGS_LEVEL", "__format": "date"}),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });

    test("refuses a value which is neither a map nor a string", () {
      expect(
        () => EnvConfigMappingModel.fromJson(["logs", "logsNb"], 3),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });
  });

  group("EnvConfigMappingModel", () {
    test("reads the mapping attributes from the keys which carry the prefix", () {
      expect(EnvConfigMappingModel.prefixKey, "__");
    });

    test("has a value equality on the variable, the type and the path", () {
      const model = EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "level"]);

      expect(model, const EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "level"]));
      expect(
        model,
        isNot(const EnvConfigMappingModel(envKey: "LOGS_LEVEL", path: ["logs", "logsNb"])),
      );
      expect(model, isNot(const EnvConfigMappingModel(envKey: "OTHER", path: ["logs", "level"])));
      expect(
        model,
        isNot(
          const EnvConfigMappingModel(
            envKey: "LOGS_LEVEL",
            path: ["logs", "level"],
            type: EnvType.number,
          ),
        ),
      );
    });
  });
}
