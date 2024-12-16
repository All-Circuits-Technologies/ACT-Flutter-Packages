// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_config_manager/src/types/env_type.dart';
import 'package:equatable/equatable.dart';

/// This model stores the mapping between the env variables the config variables
class EnvConfigMappingModel extends Equatable {
  /// The prefix for the mapping attributes
  static const prefixKey = "__";

  /// The mapping attribute for describing the config format
  static const _formatKey = "__format";

  /// The mapping attribute for describing the config name
  static const _nameKey = "__name";

  /// The environment name
  final String envKey;

  /// The type of the variable to replace
  final EnvType type;

  /// The path of the config variable to replace
  final List<String> path;

  /// The class constructor
  const EnvConfigMappingModel({
    required this.envKey,
    required this.path,
    this.type = EnvType.string,
  });

  /// Create a [EnvConfigMappingModel] from a json [value], which can be a Map or a string.
  ///
  /// The [path] is the path of the config variable the env variable replace.
  ///
  /// If a problem occurred in the paring process, an Exception is raised.
  // We use a dynamic value here because we get it from a json
  // ignore: avoid_annotating_with_dynamic
  static EnvConfigMappingModel fromJson(List<String> path, dynamic value) {
    if (value is Map<String, dynamic>) {
      return _fromDetailedJson(path, value);
    }

    if (value is! String) {
      throw Exception("The value isn't a map, nor a string, the env config mapping model isn't "
          "correctly formatted: ${jsonEncode(value)}");
    }

    return EnvConfigMappingModel(envKey: value, path: path);
  }

  /// Create a [EnvConfigMappingModel] from a map [value]. This is used when the mapping file
  /// describes the format of the env variable
  ///
  /// The [path] is the path of the config variable the env variable replace.
  ///
  /// If a problem occurred in the paring process, an Exception is raised.
  static EnvConfigMappingModel _fromDetailedJson(List<String> path, Map<String, dynamic> value) {
    final format = value[_formatKey];
    final name = value[_nameKey];

    if (format is! String || name is! String) {
      throw Exception("The env config mapping model isn't correctly formatted, we expect to have "
          "properties: $_formatKey and $_nameKey in it: ${jsonEncode(value)}");
    }

    final envType = EnvType.parseFromString(format);

    if (envType == null) {
      throw Exception(
          "The format of the env config mapping model is unknown: ${jsonEncode(value)}");
    }

    return EnvConfigMappingModel(envKey: name, path: path, type: envType);
  }

  @override
  List<Object?> get props => [envKey, type, path];
}
