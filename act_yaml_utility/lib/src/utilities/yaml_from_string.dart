// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_yaml_utility/src/utilities/yaml_to_standard_obj.dart';
import 'package:yaml/yaml.dart';

/// This class contains useful methods to load JSON objects from YAML file content
sealed class YamlFromString {
  /// This method parses a YAML from [content] and returns a JSON like the [jsonDecode] method can
  /// return.
  static dynamic fromYaml(String content) {
    dynamic jsonContent;
    try {
      final yamlContent = loadYaml(content);
      jsonContent = YamlToStandardObj.fromYamlValue(yamlContent);
    } catch (error) {
      return null;
    }

    return jsonContent;
  }

  /// This method returns a JSON object, if the content of the YAML file is a JSON list, this will
  /// return an error.
  /// Only use this method if you expect to have a JSON object in the root of your document.
  static Map<String, dynamic>? fromYamlMap(String content) {
    final value = fromYaml(content);
    if (value is! Map<String, dynamic>) {
      return null;
    }

    return value;
  }

  /// This method returns a JSON objects list, if the content of the YAML file is a JSON object,
  /// this will return an error.
  /// Only use this method if you expect to have a JSON objects list in the root of your document.
  static List<dynamic>? fromYamlList(String content) {
    final value = fromYaml(content);
    if (value is! List<dynamic>) {
      return null;
    }

    return value;
  }
}
