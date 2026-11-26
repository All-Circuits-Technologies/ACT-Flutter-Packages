// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/src/data/config_constants.dart' as config_constants;
import 'package:act_dart_config_manager/src/loaders/abs_config_reader.dart';
import 'package:act_dart_config_manager/src/types/environment.dart';
import 'package:act_dart_config_manager/src/utilities/config_file_parser.dart';
import 'package:act_dart_config_manager/src/utilities/config_from_env.dart';
import 'package:act_dart_config_manager/src/utilities/dot_env_parser.dart';
import 'package:act_dart_config_manager/src/utilities/env_config_mapping_parser.dart';
import 'package:act_dart_utility/act_dart_utility.dart';

/// This class loads the configuration: it reads the config files, the env config mapping file and
/// the dot env file through an [AbsConfigReader], parses them and merges them.
///
/// The config files and the env config mapping file are yaml or json files. Their file type isn't
/// part of their name: the loader tries the known file types, in order.
sealed class ConfigLoader {
  /// This is the separator between the name of a file and its type.
  static const _fileTypeSeparator = ".";

  /// The file types the loader tries, in order, to find a config or a mapping file.
  static const _fileTypes = ["yaml", "yml", "json"];

  /// Load the configuration of the chosen [env] and return it merged.
  ///
  /// [processEnv] are the variables of the environment of the running process.
  ///
  /// The precedence is the following (from the less to the most important):
  ///
  /// - the default config file
  /// - the config file of the chosen environment (production, qualification or development)
  /// - the local config file
  /// - the variables of the process environment
  /// - the variables of the dot env file
  ///
  /// The environment variables are only read when the env config mapping file maps them to a
  /// config variable.
  ///
  /// The method throws when a file can't be parsed: the configuration is loaded at startup and the
  /// host can't work without it.
  static Future<Map<String, dynamic>> loadConfigs({
    required AbsConfigReader reader,
    required Environment env,
    required Map<String, String> processEnv,
  }) async {
    final fileConfig = await parseFromConfigFiles(reader: reader, env: env);
    final envConfig = await parseFromEnv(reader: reader, processEnv: processEnv);

    return JsonUtility.mergeJson(baseJson: fileConfig, jsonToOverrideWith: envConfig);
  }

  /// Parse the config files of the chosen [env] and merge them.
  ///
  /// The precedence is the following (from the less to the most important): the default file, the
  /// file of the chosen environment, the local file. A missing file is ignored.
  static Future<Map<String, dynamic>> parseFromConfigFiles({
    required AbsConfigReader reader,
    required Environment env,
  }) async {
    final defaultConfig = await _parseConfigFile(reader, Environment.defaultEnv);
    final chosenConfig = await _parseConfigFile(reader, env);
    final localConfig = await _parseConfigFile(reader, Environment.local);

    var result = JsonUtility.mergeJson(baseJson: defaultConfig, jsonToOverrideWith: chosenConfig);
    result = JsonUtility.mergeJson(baseJson: result, jsonToOverrideWith: localConfig);

    return result;
  }

  /// Build a config structure from the environment variables the env config mapping file maps.
  ///
  /// [processEnv] are the variables of the environment of the running process; the variables of
  /// the dot env file override them.
  static Future<Map<String, dynamic>> parseFromEnv({
    required AbsConfigReader reader,
    required Map<String, String> processEnv,
  }) async {
    final mappingFile = await _readGuessedFile(reader, config_constants.envConfigMappingFileName);
    final mapping = EnvConfigMappingParser.fromContent(mappingFile?.content);

    final dotEnvContent = await reader.readRaw(reader.locate(config_constants.dotEnvFileName));
    final dotEnv = (dotEnvContent == null)
        ? const <String, String>{}
        : DotEnvParser.parse(dotEnvContent);

    return ConfigFromEnv.parse(mapping: mapping, processEnv: processEnv, dotEnv: dotEnv);
  }

  /// Parse the config file linked to the given [env] and return its structured config.
  static Future<Map<String, dynamic>> _parseConfigFile(
    AbsConfigReader reader,
    Environment env,
  ) async {
    final file = await _readGuessedFile(reader, env.fileName);
    return ConfigFileParser.fromContent(
      file?.content,
      description: file?.location ?? reader.locate(env.fileName),
    );
  }

  /// Read the file named [name], trying the [_fileTypes] in order.
  ///
  /// The method returns the location and the content of the first file found, or null when none
  /// exists.
  static Future<({String location, String content})?> _readGuessedFile(
    AbsConfigReader reader,
    String name,
  ) async {
    for (final type in _fileTypes) {
      final location = reader.locate("$name$_fileTypeSeparator$type");
      final content = await reader.readRaw(location);
      if (content != null) {
        return (location: location, content: content);
      }
    }

    return null;
  }
}
