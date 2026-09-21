// SPDX-FileCopyrightText: 2024 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/src/data/config_constants.dart' as config_constants;
import 'package:act_dart_config_manager/src/models/env_config_mapping_model.dart';
import 'package:act_dart_config_manager/src/types/env_type.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_dart_yaml_utility/act_dart_yaml_utility.dart';

/// This class contains useful methods to build a structured config from environment variables.
///
/// The config structure is built thanks to the env config mapping models.
sealed class ConfigFromEnv {
  /// Build a config structure from environment variables, using the [mapping].
  ///
  /// [processEnv] are the variables of the environment of the running process (or the operating
  /// system). [dotEnv] are the variables read from a dot env file.
  ///
  /// If a value exists on both supports, it's overridden by the most important. The precedence is
  /// the following (from the less to the most important):
  ///
  /// - the variables of the process environment
  /// - the variables of the dot env file
  static Map<String, dynamic> parse({
    required List<EnvConfigMappingModel> mapping,
    required Map<String, String> processEnv,
    Map<String, String> dotEnv = const {},
  }) {
    final envConfig = <String, dynamic>{};

    for (final model in mapping) {
      final value = _parseFromMapEnv(dotEnv, model) ?? _parseFromMapEnv(processEnv, model);

      if (value == null) {
        // Nothing to do
        continue;
      }

      _fillMap(envConfig, model, value);
    }

    return envConfig;
  }

  /// This method parses a value from the [mapEnv] given.
  ///
  /// This method returns null if the env isn't found or if a problem occurred.
  static dynamic _parseFromMapEnv(Map<String, String> mapEnv, EnvConfigMappingModel model) {
    if (!mapEnv.containsKey(model.envKey)) {
      return null;
    }

    return _parseEnv(model, mapEnv[model.envKey]!);
  }

  /// The method parses the string value from the [model] type
  ///
  /// The method raises an exception if the parsing failed.
  static dynamic _parseEnv(EnvConfigMappingModel model, String value) {
    switch (model.type) {
      case EnvType.string:
        return value;

      case EnvType.bool:
        return BoolUtility.parse(value);

      case EnvType.number:
        if (value.contains(config_constants.decimalSeparator)) {
          return double.parse(value);
        }
        return int.parse(value);

      case EnvType.yaml:
        return YamlFromString.fromYaml(value);
    }
  }

  /// The method fills the config map thanks to the [model] path and the given value.
  ///
  /// The method builds the config structure.
  static void _fillMap(
    Map<String, dynamic> mapToFill,
    EnvConfigMappingModel model,
    // We manipulate json value, so the value retrieved is dynamic
    // ignore: avoid_annotating_with_dynamic
    dynamic value,
  ) {
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
}
