// SPDX-FileCopyrightText: 2024 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/utilities/config_asset_loader.dart';
import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';

/// This class contains useful methods to parse config variables from assets files and returns a
/// structured config from them.
///
/// The files are yaml or json files.
sealed class ConfigFromYamlUtility {
  /// Parse the config variables from files. The method returns the files content.
  ///
  /// If a value exists on all the files, it's overridden by the most important. The precedence
  /// is the following (from the less to the most important):
  ///
  /// - default file
  /// - config file linked to environment (production, qualification or development)
  /// - local file
  static Future<Map<String, dynamic>> parseFromConfigFiles(
    String configPath,
    Environment chosenEnv,
  ) async {
    final configElements = await _parseFromConfigFile(configPath, Environment.defaultEnv);
    final chosenConfigElements = await _parseFromConfigFile(configPath, chosenEnv);
    final localConfigElements = await _parseFromConfigFile(configPath, Environment.local);

    var finalResult = JsonUtility.mergeJson(
      baseJson: configElements,
      jsonToOverrideWith: chosenConfigElements,
    );
    finalResult = JsonUtility.mergeJson(
      baseJson: finalResult,
      jsonToOverrideWith: localConfigElements,
    );

    return finalResult;
  }

  /// Parse the config variables file linked to the given [toLoad] environment and returns its
  /// content.
  ///
  /// If the file is not found the method returns an empty map, if a problem occurred when loading
  /// the file (or if it's not correctly built), the method will raise an exception.
  static Future<Map<String, dynamic>> _parseFromConfigFile(
    String configPath,
    Environment toLoad,
  ) async {
    final path = "$configPath${toLoad.fileName}";
    final content = await ConfigAssetLoader.loadRaw(path);
    return ConfigFileParser.fromContent(content, description: path);
  }
}
