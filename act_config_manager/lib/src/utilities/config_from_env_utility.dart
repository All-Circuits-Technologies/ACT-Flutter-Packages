// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_config_manager/src/data/config_constants.dart' as config_constants;
import 'package:act_config_manager/src/models/env_config_mapping_model.dart';
import 'package:act_config_manager/src/types/env_type.dart';
import 'package:act_config_manager/src/utilities/env_config_mapping_utility.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:act_yaml_utility/act_yaml_utility.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// This class contains useful methods to parse environment variables and returns a structured
/// config from them.
///
/// The env variables are retrieved from the build and runtime env variables but also the .env file.
///
/// The config structure is built thanks to the env config mapping file.
sealed class ConfigFromEnvUtility {
  /// Parse the env variables to a config structure.
  ///
  /// The config structure is built from the env config mapping file, found in the [configPath]
  /// folder.
  ///
  /// If a value exists on all the supports, it's overridden by the most important. The precedence
  /// is the following (from the less to the most important):
  ///
  /// - runtime/OS env
  /// - build env
  /// - dot env file
  static Future<Map<String, dynamic>> parseFromEnv(String configPath) async {
    final envConfig = <String, dynamic>{};

    final mappingModels = await EnvConfigMappingUtility.fromAssetBundle(
        _getConfigFilePath(configPath, config_constants.envConfigMappingFileName));
    final platformEnv = ActPlatform.environment;

    final dotEnv = (await _loadDotEnvFromAsset(configPath)) ?? {};

    for (final envMapModel in mappingModels) {
      final envValue = _parseFromDotEnv(dotEnv, envMapModel) ??
          _parseFromBuildEnv(envMapModel) ??
          _parseFromRuntimeEnv(platformEnv, envMapModel);

      if (envValue == null) {
        // Nothing to do
        continue;
      }

      _fillMap(envConfig, envMapModel, envValue);
    }

    return envConfig;
  }

  /// This method parses a value from the dot env file.
  ///
  /// This method returns null if the env isn't found or if a problem occurred.
  static dynamic _parseFromDotEnv(Map<String, String> dotEnv, EnvConfigMappingModel model) =>
      _parseFromMapEnv(dotEnv, model);

  /// This method parses a value from the OS/runtime environment variables.
  ///
  /// This method returns null if the env isn't found or if a problem occurred.
  static dynamic _parseFromRuntimeEnv(
          Map<String, String> platformEnv, EnvConfigMappingModel model) =>
      _parseFromMapEnv(platformEnv, model);

  /// This method parses a value from the [mapEnv] given.
  ///
  /// This method returns null if the env isn't found or if a problem occurred.
  static dynamic _parseFromMapEnv(Map<String, String> mapEnv, EnvConfigMappingModel model) {
    if (!mapEnv.containsKey(model.envKey)) {
      return null;
    }

    return _parseEnv(model, mapEnv[model.envKey]!);
  }

  /// This method parses a value from the build environment variables.
  ///
  /// This method returns null if the env isn't found or if a problem occurred.
  static dynamic _parseFromBuildEnv(EnvConfigMappingModel model) {
    // We explicitly search for environment variable in the app to manage it with the config
    // manager.
    // ignore: do_not_use_environment
    if (!bool.hasEnvironment(model.envKey)) {
      return null;
    }

    // We explicitly search for environment variable in the app to manage it with the config
    // manager.
    // ignore: do_not_use_environment
    final value = String.fromEnvironment(model.envKey);

    return _parseEnv(model, value);
  }

  /// The method parses the string value from the [model] type
  ///
  /// The method raises an exception if the parsing failed.
  static dynamic _parseEnv(EnvConfigMappingModel model, String value) {
    switch (model.type) {
      case EnvType.string:
        return value;

      case EnvType.bool:
        return BoolHelper.parse(value);

      case EnvType.number:
        if (value.contains(config_constants.decimalSeparator)) {
          return double.parse(value);
        }
        return int.parse(value);

      case EnvType.yaml:
        return YamlFromString.fromYaml(value);
    }
  }

  /// The method loads and parses the dot env file and get the Map\<String, String\> values.
  ///
  /// The method returns null if the file doesn't exist or if a problem occurred.
  static Future<Map<String, String>?> _loadDotEnvFromAsset(String configPath) async {
    String fileContent;

    try {
      fileContent = await rootBundle
          .loadString(_getConfigFilePath(configPath, config_constants.dotEnvFileName));
    } catch (error) {
      // The file doesn't exist or a problem occurred
      return null;
    }

    if (fileContent.isEmpty) {
      // The file exists but it's empty; the lib throws an error in this case (and cleans the env
      // map before)
      // Nothing has to be done
      return {};
    }

    final lines = LineSplitter.split(fileContent);

    final globalElements =
        dotenv.isInitialized ? Map<String, String>.from(dotenv.env) : <String, String>{};

    globalElements.addAll(const Parser().parse(lines));

    try {
      dotenv.testLoad(mergeWith: globalElements);
    } catch (error) {
      return null;
    }

    return dotenv.env;
  }

  /// The method fills the config map thanks to the [model] path and the given value.
  ///
  /// The method builds the config structure.
  // We manipulate json value, so the value retrieved is dynamic
  // ignore: avoid_annotating_with_dynamic
  static void _fillMap(Map<String, dynamic> mapToFill, EnvConfigMappingModel model, dynamic value) {
    final lastIdx = model.path.length - 1;
    var currentMap = mapToFill;
    for (var idx = 0; idx <= lastIdx; ++idx) {
      final pathElem = model.path[idx];
      if (idx != lastIdx) {
        // We have to create object
        var currentValue = currentMap[pathElem];
        if (currentValue is! Map<String, dynamic>) {
          currentMap[pathElem] = <String, dynamic>{};
          currentValue = currentMap[pathElem];
        }

        // We set the current map with the current value to work with the sub level in the next
        // iteration
        currentMap = currentValue as Map<String, dynamic>;
      } else {
        currentMap[pathElem] = value;
      }
    }
  }

  /// The method builds the config file path
  static String _getConfigFilePath(String configPath, String fileName) => "$configPath$fileName";
}
