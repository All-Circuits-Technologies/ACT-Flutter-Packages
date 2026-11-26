// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_flutter_utility/src/types/assets_bundle_result.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:flutter/services.dart';

/// This class contains useful methods to manage files stored in the assets bundle
sealed class AssetsBundleUtility {
  /// Load the content of a file stored in the assets bundle. The content is returned as a String.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  static Future<ResultWithRequiredValue<AssetsBundleResult, String>> loadStringFromAssetBundle(
    String key, {
    bool cache = true,
    MixinActLogger? logger,
  }) async {
    String? fileContent;
    try {
      fileContent = await rootBundle.loadString(key, cache: cache);
    } catch (error) {
      logger?.w(
        "The string file with key '$key' hasn't been found in the assets bundle or a problem "
        "occurred while loading it",
        error,
      );
    }

    if (fileContent == null) {
      return const ResultWithRequiredValue(status: AssetsBundleResult.notFound);
    }

    return ResultWithRequiredValue(status: AssetsBundleResult.ok, value: fileContent);
  }

  /// Load the content of a file stored in the assets bundle. The content is returned as a
  /// Uint8List.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  static Future<ResultWithRequiredValue<AssetsBundleResult, Uint8List>> loadBinaryFromAssetBundle(
    String key, {
    bool cache = true,
    MixinActLogger? logger,
  }) async {
    ByteData? byteData;
    try {
      byteData = await rootBundle.load(key);
    } catch (error) {
      logger?.w(
        "The binary file with key '$key' hasn't been found in the assets bundle or a problem "
        "occurred while loading it",
        error,
      );
    }

    if (byteData == null) {
      return const ResultWithRequiredValue(status: AssetsBundleResult.notFound);
    }

    return ResultWithRequiredValue(
      status: AssetsBundleResult.ok,
      value: byteData.buffer.asUint8List(),
    );
  }
}
