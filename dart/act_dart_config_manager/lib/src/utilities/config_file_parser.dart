// SPDX-FileCopyrightText: 2024 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/src/errors/act_config_load_exception.dart';
import 'package:act_dart_config_manager/src/errors/act_config_mapping_format_exception.dart';
import 'package:act_dart_yaml_utility/act_dart_yaml_utility.dart';

/// This class contains useful methods to parse the content of a config file (yaml or json) and
/// returns a structured config from it.
sealed class ConfigFileParser {
  /// Parse the [content] of a config file and returns its structured config.
  ///
  /// [content] is the raw content of a yaml or json file. [description] is used in the error
  /// messages to tell which file the content comes from.
  ///
  /// If [content] is null, empty or blank, the method returns an empty map. If the content can't be
  /// parsed, an [ActConfigLoadException] is raised. If the content isn't a map, an
  /// [ActConfigMappingFormatException] is raised.
  static Map<String, dynamic> fromContent(String? content, {required String description}) {
    if (content == null || content.trim().isEmpty) {
      return {};
    }

    final parsed = YamlFromString.fromYaml(content);

    if (parsed == null) {
      throw ActConfigLoadException(
        "An error occurred when tried to load the yaml config file: $description",
      );
    }

    if (parsed is! Map<String, dynamic>) {
      throw ActConfigMappingFormatException(
        "An error occurred when tried to load the yaml config file: $description; the content is "
        "not a map.",
      );
    }

    return parsed;
  }
}
