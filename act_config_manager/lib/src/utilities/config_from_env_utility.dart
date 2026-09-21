// SPDX-FileCopyrightText: 2024 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_config_manager/src/data/config_constants.dart' as config_constants;
import 'package:act_config_manager/src/utilities/env_config_mapping_utility.dart';
import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// This class contains useful methods to parse environment variables from assets and returns a
/// structured config from them.
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
    final mapping = await EnvConfigMappingUtility.fromAssetBundle(
      _getConfigFilePath(configPath, config_constants.envConfigMappingFileName),
    );
    final processEnv = ActPlatform.instance.environment;
    final dotEnv = (await _loadDotEnvFromAsset(configPath)) ?? const {};

    return ConfigFromEnv.parse(mapping: mapping, processEnv: processEnv, dotEnv: dotEnv);
  }

  /// The method loads and parses the dot env file and get the Map\<String, String\> values.
  ///
  /// The method returns null if the file doesn't exist or if a problem occurred.
  static Future<Map<String, String>?> _loadDotEnvFromAsset(String configPath) async {
    String fileContent;

    try {
      fileContent = await rootBundle.loadString(
        _getConfigFilePath(configPath, config_constants.dotEnvFileName),
      );
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

    final globalElements = dotenv.isInitialized
        ? Map<String, String>.from(dotenv.env)
        : <String, String>{};

    globalElements.addAll(const Parser().parse(lines));

    try {
      dotenv.testLoad(mergeWith: globalElements);
    } catch (error) {
      return null;
    }

    return dotenv.env;
  }

  /// The method builds the config file path
  static String _getConfigFilePath(String configPath, String fileName) => "$configPath$fileName";
}
