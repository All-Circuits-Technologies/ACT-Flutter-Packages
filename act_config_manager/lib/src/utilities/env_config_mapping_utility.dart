// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/models/env_config_mapping_model.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_yaml_utility/act_yaml_utility.dart';

/// This class contains useful methods to load and parses the env config mapping file.
///
/// This file is used to build a config structure from env variables
sealed class EnvConfigMappingUtility {
  /// This method returns the list of models to use in order to build the config object from env
  /// variables.
  ///
  /// If a problem occurred when loading the env config mapping file, an exception is raised. If the
  /// file is not found, the method returns an empty list.
  static Future<List<EnvConfigMappingModel>> fromAssetBundle(String path) async {
    final (result, content) = await YamlFromAssets.loadYaml(path, cache: false);

    if (result == AssetsBundleResult.genericError) {
      throw Exception("An error occurred when tried to load the environment config mapping file");
    }

    if (result == AssetsBundleResult.notFound || content == null) {
      // No need to go further
      return [];
    }

    final models = <EnvConfigMappingModel>[];
    _parseYamlContent(content, models);
    return models;
  }

  /// The method is used to parse a yaml object and creates the [toFill] list.
  ///
  /// The method is recursive with the [_parseYamlMap] method.
  static void _parseYamlContent(
    dynamic value,
    List<EnvConfigMappingModel> toFill, {
    List<String>? path,
  }) {
    if (value is List<dynamic>) {
      throw Exception("The env config mapping yaml or json file can't contain array or list");
    }

    if (value is Map<String, dynamic>) {
      return _parseYamlMap(value, toFill, path: path);
    }

    if (value is! String) {
      throw Exception("The env config mapping yaml or json isn't well formatted, the value has to "
          "be a map or a string");
    }

    toFill.add(EnvConfigMappingModel.fromJson(path!, value));
  }

  /// The method is used to parse a yaml map object and creates the [toFill] list.
  ///
  /// The method is recursive with the [_parseYamlMap] method.
  static void _parseYamlMap(
    Map<String, dynamic> value,
    List<EnvConfigMappingModel> toFill, {
    List<String>? path,
  }) {
    for (final entry in value.entries) {
      if (entry.key.startsWith(EnvConfigMappingModel.prefixKey)) {
        toFill.add(EnvConfigMappingModel.fromJson(path ?? [], value));
        break;
      }

      final tmpPath = (path != null) ? List<String>.from(path) : <String>[];
      tmpPath.add(entry.key);

      _parseYamlContent(entry.value, toFill, path: tmpPath);
    }
  }
}
