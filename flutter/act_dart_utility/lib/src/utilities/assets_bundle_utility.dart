// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter/services.dart';

/// This is the result of the load string method from assets bundle
enum AssetsBundleResult {
  /// Everything is ok
  ok,

  /// The asset hasn't been found
  notFound,

  /// A generic error occurred
  genericError,
}

/// This class contains useful methods to manage files stored in the assets bundle
sealed class AssetsBundleUtility {
  /// Load the content of a file stored in the assets bundle. The content is returned as a String.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  static Future<({AssetsBundleResult status, String? data})> loadStringFromAssetBundle(
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
      return (status: AssetsBundleResult.notFound, data: null);
    }

    return (status: AssetsBundleResult.ok, data: fileContent);
  }

  /// Load the content of a file stored in the assets bundle. The content is returned as a
  /// Uint8List.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  static Future<({AssetsBundleResult status, Uint8List? data})> loadBinaryFromAssetBundle(
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
      return (status: AssetsBundleResult.notFound, data: null);
    }

    return (status: AssetsBundleResult.ok, data: byteData.buffer.asUint8List());
  }
}
