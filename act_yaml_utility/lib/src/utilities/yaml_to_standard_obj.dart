// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:yaml/yaml.dart';

/// This class contains useful methods to transform YAML objects of the yaml package to JSON
/// objects.
/// The object returned are like the objects the [jsonDecode] method can return.
///
/// This loses specific YAML elements like comments.
sealed class YamlToStandardObj {
  /// Convert [YamlDocument] to Json object
  ///
  /// This loses specific YAML elements like comments.
  static dynamic fromDoc(YamlDocument doc) {
    final node = doc.contents;
    return _fromYamlNode(node);
  }

  /// Convert a list of [YamlDocument] to a JSON objects list
  ///
  /// This loses specific YAML elements like comments.
  static List<dynamic> fromDocs(List<YamlDocument> docs) {
    final jsonDocs = [];
    for (final doc in docs) {
      jsonDocs.add(fromDoc(doc));
    }

    return jsonDocs;
  }

  /// Convert a [YamlMap] object to a JSON map. The method returns the same kind of objects, the
  /// [jsonDecode] method returns.
  ///
  /// This loses specific YAML elements like comments.
  ///
  /// This method is recursive with [fromYamlList], [_fromYamlNode] and [fromYamlValue] methods.
  static Map<String, dynamic> fromYamlMap(YamlMap map) {
    final newMap = <String, dynamic>{};

    for (final entry in map.entries) {
      newMap[entry.key as String] = fromYamlValue(entry.value);
    }

    return newMap;
  }

  /// Convert a [YamlList] object to a JSON objects list. The method returns the same kind of
  /// objects, the [jsonDecode] method returns.
  ///
  /// This loses specific YAML elements like comments.
  ///
  /// This method is recursive with [fromYamlMap], [_fromYamlNode] and [fromYamlValue] methods.
  static List<dynamic> fromYamlList(YamlList list) {
    final newList = [];

    for (final element in list) {
      newList.add(fromYamlValue(element));
    }

    return newList;
  }

  /// Convert a [YamlNode] object to a JSON object. The method returns the same kind of
  /// objects, the [jsonDecode] method returns.
  ///
  /// This loses specific YAML elements like comments.
  ///
  /// This method is recursive with [fromYamlList], [fromYamlMap] and [fromYamlValue] methods.
  static dynamic _fromYamlNode(YamlNode node) {
    if (node is YamlMap) {
      return fromYamlMap(node);
    }

    if (node is YamlList) {
      return fromYamlList(node);
    }

    return node.value;
  }

  /// Convert a yaml dynamic object to a JSON object. The method returns the same kind of
  /// objects, the [jsonDecode] method returns.
  ///
  /// This loses specific YAML elements like comments.
  ///
  /// This method is recursive with [fromYamlList], [fromYamlMap] and [_fromYamlNode] methods.
  // We manipulate yaml value, so the value got is dynamic
  // ignore: avoid_annotating_with_dynamic
  static dynamic fromYamlValue(dynamic value) {
    // YamlList and YamlMap inherits from YamlNode
    if (value is YamlNode) {
      return _fromYamlNode(value);
    }

    if (value is YamlDocument) {
      return fromDoc(value);
    }

    if (value is List<YamlDocument>) {
      return fromDocs(value);
    }

    return value;
  }
}
