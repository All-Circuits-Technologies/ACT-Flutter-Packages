// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_config_manager/file_config_loader.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;

  /// Write [content] to the file named [name] of the config directory.
  void writeFile(String name, String content) {
    File("${directory.path}${Platform.pathSeparator}$name").writeAsStringSync(content);
  }

  /// Load the configuration of the directory for the given [env].
  Future<ConfigStore> load({Environment env = Environment.production}) =>
      FileConfigLoader.load(logger: const SilentLogger(), configDir: directory.path, env: env);

  setUp(() {
    directory = Directory.systemTemp.createTempSync("act_dart_config_manager_test");
  });

  tearDown(() {
    ConfigStore.instanceOrNull?.dispose();
    directory.deleteSync(recursive: true);
  });

  group("FileConfigLoader.load", () {
    test("creates the store and returns it", () async {
      final store = await load();

      expect(ConfigStore.instanceOrNull, same(store));
    });

    test("reads the values of the default file", () async {
      writeFile("default.yaml", "logs:\n  level: warning");

      final store = await load();

      expect(store.tryToGet<String>("logs.level"), "warning");
    });

    test("creates an empty store when the directory has no file", () async {
      final store = await load();

      expect(store.tryToGet<String>("logs.level"), isNull);
    });

    test("lets the file of the environment override the default one", () async {
      writeFile("default.yaml", "logs:\n  level: warning\n  logsNb: 3");
      writeFile("production.yaml", "logs:\n  level: error");

      final store = await load();

      expect(store.tryToGet<String>("logs.level"), "error");
      expect(store.tryToGet<int>("logs.logsNb"), 3);
    });

    test("reads the file of the chosen environment and not the ones of the others", () async {
      writeFile("production.yaml", "host: prod.example.com");
      writeFile("qualification.yaml", "host: qualif.example.com");

      final store = await load(env: Environment.qualification);

      expect(store.tryToGet<String>("host"), "qualif.example.com");
    });

    test("lets the local file override the file of the environment", () async {
      writeFile("default.yaml", "logs:\n  level: warning");
      writeFile("production.yaml", "logs:\n  level: error");
      writeFile("local.yaml", "logs:\n  level: trace");

      final store = await load();

      expect(store.tryToGet<String>("logs.level"), "trace");
    });

    test("reads a JSON file as well as a YAML one", () async {
      writeFile("default.json", '{"logs": {"level": "warning"}}');

      final store = await load();

      expect(store.tryToGet<String>("logs.level"), "warning");
    });

    test("reads a yml file as well as a yaml one", () async {
      writeFile("default.yml", "logs:\n  level: warning");

      final store = await load();

      expect(store.tryToGet<String>("logs.level"), "warning");
    });

    test("builds the configuration from the dot env file and the mapping file", () async {
      writeFile("env_config_mapping.yaml", "logs:\n  level: ACT_TEST_LOGS_LEVEL");
      writeFile(".env", "ACT_TEST_LOGS_LEVEL=warning");

      final store = await load();

      expect(store.tryToGet<String>("logs.level"), "warning");
    });

    test("lets the environment variables override the config files", () async {
      writeFile("default.yaml", "logs:\n  level: warning");
      writeFile("env_config_mapping.yaml", "logs:\n  level: ACT_TEST_LOGS_LEVEL");
      writeFile(".env", "ACT_TEST_LOGS_LEVEL=error");

      final store = await load();

      expect(store.tryToGet<String>("logs.level"), "error");
    });
  });
}
