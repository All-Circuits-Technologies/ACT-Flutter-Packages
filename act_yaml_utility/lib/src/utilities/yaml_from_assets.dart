// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_yaml_utility/src/utilities/yaml_to_standard_obj.dart';
import 'package:yaml/yaml.dart' as yaml;

/// This class contains methods used to load yaml files from assets
///
/// Because YAML files can contain JSON, we consider that we can parse json files from those
/// methods.
sealed class YamlFromAssets {
  /// This is the separator between the file type and name
  static const fileTypeSeparator = ".";

  /// This is the .yaml suffix for yaml file
  static const yamlFileType = "yaml";

  /// This is the .yml suffix for yaml file
  static const ymlFileType = "yml";

  /// This is the .json suffix for json file
  static const jsonFileType = "json";

  /// Load the content of a YAML file from assets bundle and returns a JSON representation. The
  /// comments are removed.
  ///
  /// [key] is the the name of the file to parse. If [key] has no file suffix, the method will guess
  /// and search the file with the different [yamlFileTypes] given.
  ///
  /// For instance, if key is equal to `local`, the method will try to load the files: local.yaml,
  /// local.yml and local.json.
  /// The method doesn't load all, it stops to search at the first file found. Therefore, the
  /// [yamlFileTypes] order is important if you want to give a priority to the finding.
  ///
  /// [cache] is used to keep (or not) the asset in app cache. If you only load the file once,
  /// better to set [cache] to false.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  ///
  /// The second part of the result contains the same kind of objects the jsonDecode can return.
  static Future<(AssetsBundleResult, dynamic)> loadYaml(
    String key, {
    bool cache = true,
    List<String> yamlFileTypes = const [
      yamlFileType,
      ymlFileType,
      jsonFileType,
    ],
  }) async {
    final (result, content) = await _guessTypeAndLoadAssetsContent(
      key,
      cache: cache,
      yamlFileTypes: yamlFileTypes,
    );

    if (result != AssetsBundleResult.ok) {
      return (result, null);
    }

    if (content == null) {
      return (AssetsBundleResult.ok, null);
    }

    dynamic jsonContent;
    try {
      final yamlContent = yaml.loadYaml(content);
      jsonContent = YamlToStandardObj.fromYamlValue(yamlContent);
    } catch (error) {
      return (AssetsBundleResult.genericError, null);
    }

    return (AssetsBundleResult.ok, jsonContent);
  }

  /// Load the content of a YAML file from assets bundle and returns a JSON representation. The
  /// comments are removed.
  ///
  /// [key] is the the name of the file to parse. If [key] has no file suffix, the method will guess
  /// and search the file with the different [yamlFileTypes] given.
  ///
  /// For instance, if key is equal to `local`, the method will try to load the files: local.yaml,
  /// local.yml and local.json.
  /// The method doesn't load all, it stops to search at the first file found. Therefore, the
  /// [yamlFileTypes] order is important if you want to give a priority to the finding.
  ///
  /// [cache] is used to keep (or not) the asset in app cache. If you only load the file once,
  /// better to set [cache] to false.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  ///
  /// The second part of the result contains the same kind of objects the jsonDecode can return.
  ///
  /// This method returns a JSON object, if the content of the YAML file is a JSON list, this will
  /// return an error.
  /// Only use this method if you expect to have a JSON object in the root of your document.
  static Future<(AssetsBundleResult, Map<String, dynamic>?)> loadYamlMap(
    String key, {
    bool cache = true,
    List<String> yamlFileTypes = const [
      yamlFileType,
      ymlFileType,
      jsonFileType,
    ],
  }) async {
    final (result, content) = await loadYaml(key, cache: cache, yamlFileTypes: yamlFileTypes);

    if (result != AssetsBundleResult.ok) {
      return (result, null);
    }

    if (content == null) {
      return (AssetsBundleResult.ok, <String, dynamic>{});
    }

    if (content is! Map<String, dynamic>) {
      return (AssetsBundleResult.genericError, null);
    }

    return (result, content);
  }

  /// Load the content of a YAML file from assets bundle and returns a JSON representation. The
  /// comments are removed.
  ///
  /// [key] is the the name of the file to parse. If [key] has no file suffix, the method will guess
  /// and search the file with the different [yamlFileTypes] given.
  ///
  /// For instance, if key is equal to `local`, the method will try to load the files: local.yaml,
  /// local.yml and local.json.
  /// The method doesn't load all, it stops to search at the first file found. Therefore, the
  /// [yamlFileTypes] order is important if you want to give a priority to the finding.
  ///
  /// [cache] is used to keep (or not) the asset in app cache. If you only load the file once,
  /// better to set [cache] to false.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  ///
  /// The second part of the result contains the same kind of objects the jsonDecode can return.
  ///
  /// This method returns a JSON objects list, if the content of the YAML file is a JSON object,
  /// this will return an error.
  /// Only use this method if you expect to have a JSON objects list in the root of your document.
  static Future<(AssetsBundleResult, List<dynamic>?)> loadYamlList(
    String key, {
    bool cache = true,
    List<String> yamlFileTypes = const [
      yamlFileType,
      ymlFileType,
      jsonFileType,
    ],
  }) async {
    final (result, content) = await loadYaml(key, cache: cache, yamlFileTypes: yamlFileTypes);

    if (result != AssetsBundleResult.ok) {
      return (result, null);
    }

    if (content == null) {
      return (AssetsBundleResult.ok, []);
    }

    if (content is! List<dynamic>) {
      return (AssetsBundleResult.genericError, null);
    }

    return (result, content);
  }

  /// This method tries to guess the file suffix and load the YAML file from assets bundle.
  ///
  /// If the [key] has already a file suffix, the method tries to load the file without using the
  /// [yamlFileTypes].
  ///
  /// [cache] is used to keep (or not) the asset in app cache. If you only load the file once,
  /// better to set [cache] to false.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  static Future<(AssetsBundleResult, String?)> _guessTypeAndLoadAssetsContent(
    String key, {
    bool cache = true,
    List<String> yamlFileTypes = const [
      yamlFileType,
      ymlFileType,
      jsonFileType,
    ],
  }) async {
    final sepIdx = key.indexOf(fileTypeSeparator);

    String? content;
    if (sepIdx >= 0) {
      // We don't need to test for all the file types, the developer has already chosen one
      final result = await _loadAssetsContent(
        key,
        cache: cache,
      );

      if (result.$1 != AssetsBundleResult.ok) {
        return result;
      }

      content = result.$2;
    } else {
      for (final type in yamlFileTypes) {
        final result = await _loadAssetsContent(
          "$key$fileTypeSeparator$type",
          cache: cache,
        );

        if (result.$1 == AssetsBundleResult.genericError) {
          return result;
        }

        if (result.$1 == AssetsBundleResult.ok && result.$2 != null) {
          // No need to continue
          content = result.$2;
          break;
        }
      }
    }

    if (content == null) {
      // It means that we found nothing
      return (AssetsBundleResult.notFound, null);
    }

    return (AssetsBundleResult.ok, content);
  }

  /// Load the YAML file from the assets bundle thanks to the [key].
  ///
  /// [cache] is used to keep (or not) the asset in app cache. If you only load the file once,
  /// better to set [cache] to false.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  static Future<(AssetsBundleResult, String?)> _loadAssetsContent(
    String key, {
    bool cache = true,
  }) async {
    // We don't need to test for all the file types, the developer has already chosen one
    final (result, content) = await AssetsBundleUtility.loadStringFromAssetBundle(
      key,
      cache: cache,
    );

    if (result != AssetsBundleResult.ok) {
      return (result, null);
    }

    if (content == null) {
      // No need to go further
      return (AssetsBundleResult.ok, null);
    }

    return (AssetsBundleResult.ok, content);
  }
}
