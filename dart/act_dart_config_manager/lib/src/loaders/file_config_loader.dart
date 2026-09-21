// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_dart_config_manager/src/data/config_constants.dart' as config_constants;
import 'package:act_dart_config_manager/src/services/config_store.dart';
import 'package:act_dart_config_manager/src/types/environment.dart';
import 'package:act_dart_config_manager/src/utilities/config_file_parser.dart';
import 'package:act_dart_config_manager/src/utilities/config_from_env.dart';
import 'package:act_dart_config_manager/src/utilities/dot_env_parser.dart';
import 'package:act_dart_config_manager/src/utilities/env_config_mapping_parser.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';

/// This class loads the configuration from the file system and fills the [ConfigStore].
///
/// It's the file system counterpart of the config manager which reads the configuration from the
/// assets bundle: it reads the same kind of files (yaml or json config files, env config mapping
/// file and dot env file) but from a directory of the file system, which lets the configuration be
/// changed without recompiling the host.
sealed class FileConfigLoader {
  /// The logger category linked to this loader.
  static const _loggerCategory = "conf";

  /// The name of the environment variable which overrides the directory the configuration is read
  /// from.
  static const configDirEnvKey = "ACT_CONFIG_DIR";

  /// The directory the configuration is read from when neither an explicit one nor the
  /// [configDirEnvKey] environment variable gives one.
  static const defaultConfigDir = "config";

  /// The file types the loader tries, in order, to find a config or a mapping file.
  static const _fileTypes = ["yaml", "yml", "json"];

  /// Load the configuration from the file system and create the [ConfigStore].
  ///
  /// The directory the files are read from is [configDir] when it's given, else the value of the
  /// [configDirEnvKey] environment variable, else [defaultConfigDir].
  ///
  /// The environment is [env] when it's given, else the one the [Environment.envType] environment
  /// variable targets, else [Environment.development].
  ///
  /// The precedence of the config files is (from the less to the most important): the default file,
  /// the file of the chosen environment, the local file. The environment variables override the
  /// config files.
  static Future<ConfigStore> load({
    required MixinActLogger logger,
    String? configDir,
    Environment? env,
  }) async {
    final subLogger = logger.createAbsSubLogger(subCategory: _loggerCategory);
    final processEnv = Platform.environment;

    final directory = configDir ?? processEnv[configDirEnvKey] ?? defaultConfigDir;
    final chosenEnv = env ?? Environment.fromString(processEnv[Environment.envType] ?? "");

    final fileConfig = await _parseFromConfigFiles(directory, chosenEnv);
    final envConfig = await _parseFromEnv(directory, processEnv);

    final finalValue = JsonUtility.mergeJson(
      baseJson: fileConfig,
      jsonToOverrideWith: envConfig,
    );

    final store = ConfigStore.create(logger: subLogger, configs: finalValue);

    subLogger.i(
      "Config store loaded from the directory '$directory' with environment: $chosenEnv",
    );

    return store;
  }

  /// Parse the config files of the [directory] and merge them following their precedence.
  static Future<Map<String, dynamic>> _parseFromConfigFiles(
    String directory,
    Environment chosenEnv,
  ) async {
    final defaultConfig = await _parseConfigFile(directory, Environment.defaultEnv);
    final chosenConfig = await _parseConfigFile(directory, chosenEnv);
    final localConfig = await _parseConfigFile(directory, Environment.local);

    var result = JsonUtility.mergeJson(
      baseJson: defaultConfig,
      jsonToOverrideWith: chosenConfig,
    );
    result = JsonUtility.mergeJson(
      baseJson: result,
      jsonToOverrideWith: localConfig,
    );

    return result;
  }

  /// Parse the config file linked to the given [env] and return its structured config.
  static Future<Map<String, dynamic>> _parseConfigFile(String directory, Environment env) async {
    final path = _join(directory, env.fileName);
    final content = await _readGuessedFile(path);
    return ConfigFileParser.fromContent(content, description: path);
  }

  /// Parse the environment variables (the process ones and the dot env ones) into a structured
  /// config.
  static Future<Map<String, dynamic>> _parseFromEnv(
    String directory,
    Map<String, String> processEnv,
  ) async {
    final mappingContent = await _readGuessedFile(
      _join(directory, config_constants.envConfigMappingFileName),
    );
    final mapping = EnvConfigMappingParser.fromContent(mappingContent);

    final dotEnvContent = await _readFile(_join(directory, config_constants.dotEnvFileName));
    final dotEnv = (dotEnvContent == null)
        ? const <String, String>{}
        : DotEnvParser.parse(dotEnvContent);

    return ConfigFromEnv.parse(mapping: mapping, processEnv: processEnv, dotEnv: dotEnv);
  }

  /// Read the content of the file at [pathWithoutType], trying the [_fileTypes] in order.
  ///
  /// The method returns the content of the first file found, or null when none exists.
  static Future<String?> _readGuessedFile(String pathWithoutType) async {
    for (final type in _fileTypes) {
      final content = await _readFile("$pathWithoutType.$type");
      if (content != null) {
        return content;
      }
    }

    return null;
  }

  /// Read the content of the file at [path], or null when it doesn't exist.
  static Future<String?> _readFile(String path) async {
    final file = File(path);

    if (!file.existsSync()) {
      return null;
    }

    return file.readAsString();
  }

  /// Join a [directory] and a [name] with the separator of the platform.
  static String _join(String directory, String name) {
    if (directory.isEmpty || directory.endsWith(Platform.pathSeparator)) {
      return "$directory$name";
    }

    return "$directory${Platform.pathSeparator}$name";
  }
}
