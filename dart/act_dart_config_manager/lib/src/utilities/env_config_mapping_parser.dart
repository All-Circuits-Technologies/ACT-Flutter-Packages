// SPDX-FileCopyrightText: 2024 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/src/errors/act_config_load_exception.dart';
import 'package:act_dart_config_manager/src/errors/act_config_mapping_format_exception.dart';
import 'package:act_dart_config_manager/src/models/env_config_mapping_model.dart';
import 'package:act_dart_yaml_utility/act_dart_yaml_utility.dart';

/// This class contains useful methods to parse the content of the env config mapping file.
///
/// This file is used to build a config structure from env variables.
sealed class EnvConfigMappingParser {
  /// This method returns the list of models to use in order to build the config object from env
  /// variables.
  ///
  /// [content] is the raw content of the env config mapping yaml or json file.
  ///
  /// If [content] is null, empty or blank, the method returns an empty list. If the content can't
  /// be parsed, an [ActConfigLoadException] is raised. If the content isn't correctly built, an
  /// [ActConfigMappingFormatException] is raised.
  static List<EnvConfigMappingModel> fromContent(String? content) {
    if (content == null || content.trim().isEmpty) {
      return [];
    }

    final parsed = YamlFromString.fromYaml(content);

    if (parsed == null) {
      throw ActConfigLoadException(
        "An error occurred when tried to load the environment config mapping file",
      );
    }

    final models = <EnvConfigMappingModel>[];
    _parseContent(parsed, models);
    return models;
  }

  /// The method is used to parse a yaml object and creates the [toFill] list.
  ///
  /// The method is recursive with the [_parseMap] method.
  static void _parseContent(
    // This method manipulates YAML value; therefore, it's ok to have dynamic here
    // ignore: avoid_annotating_with_dynamic
    dynamic value,
    List<EnvConfigMappingModel> toFill, {
    List<String>? path,
  }) {
    if (value is List<dynamic>) {
      throw ActConfigMappingFormatException(
        "The env config mapping yaml or json file can't contain array or list",
      );
    }

    if (value is Map<String, dynamic>) {
      return _parseMap(value, toFill, path: path);
    }

    if (value is! String) {
      throw ActConfigMappingFormatException(
        "The env config mapping yaml or json isn't well formatted, the value has to "
        "be a map or a string",
      );
    }

    toFill.add(EnvConfigMappingModel.fromJson(path!, value));
  }

  /// The method is used to parse a yaml map object and creates the [toFill] list.
  ///
  /// The method is recursive with the [_parseContent] method.
  static void _parseMap(
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

      _parseContent(entry.value, toFill, path: tmpPath);
    }
  }
}
