// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:test/test.dart';

/// A reader which serves the config files from a map, keyed by their location.
class _MapConfigReader extends AbsConfigReader {
  /// The content of the files, keyed by their location.
  final Map<String, String> files;

  /// The locations the loader has read, in order.
  final List<String> reads = [];

  /// Class constructor
  _MapConfigReader(this.files);

  @override
  String locate(String fileName) => "config/$fileName";

  @override
  Future<String?> readRaw(String location) async {
    reads.add(location);
    return files[location];
  }
}

void main() {
  group("ConfigLoader.parseFromConfigFiles", () {
    /// Parse the config files [files] serves for the given [env].
    Future<Map<String, dynamic>> parse(
      Map<String, String> files, {
      Environment env = Environment.production,
    }) => ConfigLoader.parseFromConfigFiles(reader: _MapConfigReader(files), env: env);

    test("returns the values of the default file", () async {
      expect(await parse({"config/default.yaml": "logs:\n  level: warning"}), {
        "logs": {"level": "warning"},
      });
    });

    test("returns an empty configuration when no file exists", () async {
      expect(await parse({}), isEmpty);
    });

    test("reads the file of the chosen environment and not the ones of the others", () async {
      final configs = await parse({
        "config/production.yaml": "host: prod.example.com",
        "config/qualification.yaml": "host: qualif.example.com",
        "config/development.yaml": "host: dev.example.com",
      }, env: Environment.qualification);

      expect(configs, {"host": "qualif.example.com"});
    });

    test("lets the file of the environment override the default one", () async {
      final configs = await parse({
        "config/default.yaml": "logs:\n  level: warning\n  logsNb: 3",
        "config/production.yaml": "logs:\n  level: error",
      });

      expect(configs, {
        "logs": {"level": "error", "logsNb": 3},
      });
    });

    test("lets the local file override the file of the environment", () async {
      final configs = await parse({
        "config/default.yaml": "logs:\n  level: warning",
        "config/production.yaml": "logs:\n  level: error",
        "config/local.yaml": "logs:\n  level: trace",
      });

      expect(configs, {
        "logs": {"level": "trace"},
      });
    });

    test("merges the files down to the leaves of the configuration", () async {
      final configs = await parse({
        "config/default.yaml": "firebase:\n  crash:\n    enable: false\n    auto: false",
        "config/local.yaml": "firebase:\n  crash:\n    enable: true",
      });

      expect(configs, {
        "firebase": {
          "crash": {"enable": true, "auto": false},
        },
      });
    });

    test("reads a yml or a JSON file as well as a yaml one", () async {
      final configs = await parse({
        "config/default.yml": "logs:\n  level: warning",
        "config/production.json": '{"host": "prod.example.com"}',
      });

      expect(configs, {
        "logs": {"level": "warning"},
        "host": "prod.example.com",
      });
    });

    test("prefers the yaml file, then the yml one, then the JSON one", () async {
      final configs = await parse({
        "config/default.yaml": "source: yaml",
        "config/default.yml": "source: yml",
        "config/default.json": '{"source": "json"}',
        "config/local.yml": "other: yml",
        "config/local.json": '{"other": "json"}',
      });

      expect(configs, {"source": "yaml", "other": "yml"});
    });

    test("reads the files through the locations the reader gives", () async {
      final reader = _MapConfigReader({"config/default.yaml": ""});

      await ConfigLoader.parseFromConfigFiles(reader: reader, env: Environment.production);

      expect(reader.reads, [
        "config/default.yaml",
        "config/production.yaml",
        "config/production.yml",
        "config/production.json",
        "config/local.yaml",
        "config/local.yml",
        "config/local.json",
      ]);
    });

    test("accepts an empty file", () async {
      expect(await parse({"config/default.yaml": ""}), isEmpty);
    });

    test("throws, quoting the location of the file, when a file cannot be parsed", () async {
      expect(
        () => parse({"config/default.yml": "logs:\n  - level\n level: warning"}),
        throwsA(
          isA<ActConfigLoadException>().having(
            (error) => error.toString(),
            "message",
            contains("config/default.yml"),
          ),
        ),
      );
    });

    test("throws when the content of a file is not a map", () async {
      expect(
        () => parse({"config/default.yaml": "- first\n- second"}),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });
  });

  group("ConfigLoader.parseFromEnv", () {
    /// Build the configuration from the environment variables, with the files [files] serves and
    /// the [processEnv] variables.
    Future<Map<String, dynamic>> parse(
      Map<String, String> files, {
      Map<String, String> processEnv = const {},
    }) => ConfigLoader.parseFromEnv(reader: _MapConfigReader(files), processEnv: processEnv);

    test("returns an empty configuration when there is no mapping file", () async {
      expect(await parse({"config/.env": "LOGS_LEVEL=warning"}), isEmpty);
    });

    test("builds the configuration structure the mapping file describes", () async {
      final configs = await parse({
        "config/env_config_mapping.yaml": "logs:\n  console:\n    level: LOGS_LEVEL",
        "config/.env": "LOGS_LEVEL=warning",
      });

      expect(configs, {
        "logs": {
          "console": {"level": "warning"},
        },
      });
    });

    test("reads a mapping file written in JSON", () async {
      final configs = await parse({
        "config/env_config_mapping.json": '{"logs": {"level": "LOGS_LEVEL"}}',
        "config/.env": "LOGS_LEVEL=warning",
      });

      expect(configs, {
        "logs": {"level": "warning"},
      });
    });

    test("reads the variables of the environment of the process", () async {
      final configs = await parse(
        {"config/env_config_mapping.yaml": "logs:\n  level: LOGS_LEVEL"},
        processEnv: {"LOGS_LEVEL": "error"},
      );

      expect(configs, {
        "logs": {"level": "error"},
      });
    });

    test("lets the dot env file override the environment of the process", () async {
      final configs = await parse(
        {
          "config/env_config_mapping.yaml": "logs:\n  level: LOGS_LEVEL\n  logsNb: LOGS_NB",
          "config/.env": "LOGS_LEVEL=warning",
        },
        processEnv: {"LOGS_LEVEL": "error", "LOGS_NB": "3"},
      );

      expect(configs, {
        "logs": {"level": "warning", "logsNb": "3"},
      });
    });

    test("accepts an empty dot env file", () async {
      final configs = await parse({
        "config/env_config_mapping.yaml": "logs:\n  level: LOGS_LEVEL",
        "config/.env": "",
      });

      expect(configs, isEmpty);
    });

    test("refuses a mapping file which cannot be parsed", () async {
      expect(
        () => parse({"config/env_config_mapping.yaml": "logs:\n  - level\n level: LOGS_LEVEL"}),
        throwsA(isA<ActConfigLoadException>()),
      );
    });
  });

  group("ConfigLoader.loadConfigs", () {
    test("lets the environment variables override the config files", () async {
      final configs = await ConfigLoader.loadConfigs(
        reader: _MapConfigReader({
          "config/default.yaml": "logs:\n  level: warning\n  logsNb: 3",
          "config/env_config_mapping.yaml": "logs:\n  level: LOGS_LEVEL",
          "config/.env": "LOGS_LEVEL=trace",
        }),
        env: Environment.production,
        processEnv: const {},
      );

      expect(configs, {
        "logs": {"level": "trace", "logsNb": 3},
      });
    });

    test("returns an empty configuration when no file exists", () async {
      final configs = await ConfigLoader.loadConfigs(
        reader: _MapConfigReader({}),
        env: Environment.production,
        processEnv: const {"LOGS_LEVEL": "trace"},
      );

      expect(configs, isEmpty);
    });
  });
}
