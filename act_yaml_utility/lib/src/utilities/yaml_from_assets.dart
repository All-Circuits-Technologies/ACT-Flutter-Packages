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
  static Future<({AssetsBundleResult status, dynamic data})> loadYaml(
    String key, {
    bool cache = true,
    List<String> yamlFileTypes = const [
      yamlFileType,
      ymlFileType,
      jsonFileType,
    ],
  }) async {
    final result = await _guessTypeAndLoadAssetsContent(
      key,
      cache: cache,
      yamlFileTypes: yamlFileTypes,
    );

    if (result.status != AssetsBundleResult.ok) {
      return (status: result.status, data: null);
    }

    if (result.data == null) {
      return (status: AssetsBundleResult.ok, data: null);
    }

    dynamic jsonContent;
    try {
      final yamlContent = yaml.loadYaml(result.data!);
      jsonContent = YamlToStandardObj.fromYamlValue(yamlContent);
    } catch (error) {
      return (status: AssetsBundleResult.genericError, data: null);
    }

    return (status: AssetsBundleResult.ok, data: jsonContent);
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
  static Future<({AssetsBundleResult status, Map<String, dynamic>? data})> loadYamlMap(
    String key, {
    bool cache = true,
    List<String> yamlFileTypes = const [
      yamlFileType,
      ymlFileType,
      jsonFileType,
    ],
  }) async {
    final result = await loadYaml(key, cache: cache, yamlFileTypes: yamlFileTypes);

    if (result.status != AssetsBundleResult.ok) {
      return (status: result.status, data: null);
    }

    final content = result.data;
    if (content == null) {
      return (status: AssetsBundleResult.ok, data: <String, dynamic>{});
    }

    if (content is! Map<String, dynamic>) {
      return (status: AssetsBundleResult.genericError, data: null);
    }

    return (status: result.status, data: content);
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
  static Future<({AssetsBundleResult status, List<dynamic>? data})> loadYamlList(
    String key, {
    bool cache = true,
    List<String> yamlFileTypes = const [
      yamlFileType,
      ymlFileType,
      jsonFileType,
    ],
  }) async {
    final result = await loadYaml(key, cache: cache, yamlFileTypes: yamlFileTypes);

    if (result.status != AssetsBundleResult.ok) {
      return (status: result.status, data: null);
    }

    final content = result.data;
    if (content == null) {
      return (status: AssetsBundleResult.ok, data: []);
    }

    if (content is! List<dynamic>) {
      return (status: AssetsBundleResult.genericError, data: null);
    }

    return (status: result.status, data: content);
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
  static Future<({AssetsBundleResult status, String? data})> _guessTypeAndLoadAssetsContent(
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

      if (result.status != AssetsBundleResult.ok) {
        return result;
      }

      content = result.data;
    } else {
      for (final type in yamlFileTypes) {
        final result = await _loadAssetsContent(
          "$key$fileTypeSeparator$type",
          cache: cache,
        );

        if (result.status == AssetsBundleResult.genericError) {
          return result;
        }

        if (result.status == AssetsBundleResult.ok && result.data != null) {
          // No need to continue
          content = result.data;
          break;
        }
      }
    }

    if (content == null) {
      // It means that we found nothing
      return (status: AssetsBundleResult.notFound, data: null);
    }

    return (status: AssetsBundleResult.ok, data: content);
  }

  /// Load the YAML file from the assets bundle thanks to the [key].
  ///
  /// [cache] is used to keep (or not) the asset in app cache. If you only load the file once,
  /// better to set [cache] to false.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  static Future<({AssetsBundleResult status, String? data})> _loadAssetsContent(
    String key, {
    bool cache = true,
  }) async {
    // We don't need to test for all the file types, the developer has already chosen one
    final result = await AssetsBundleUtility.loadStringFromAssetBundle(
      key,
      cache: cache,
    );

    if (result.status != AssetsBundleResult.ok || result.data == null) {
      // No need to go further
      return (status: result.status, data: null);
    }

    return result;
  }
}
