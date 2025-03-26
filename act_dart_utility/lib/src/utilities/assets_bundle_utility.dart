// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/services.dart';

/// This is the result of the load string method from assets bundle
enum AssetsBundleResult {
  /// Everything is ok
  ok,

  /// The asset hasn't been found
  notFound,

  /// A generic error occurred
  genericError;
}

/// This class contains useful methods to manage files stored in the assets bundle
sealed class AssetsBundleUtility {
  /// Load the content of a file stored in the assets bundle. The content is returned as a String.
  ///
  /// If the first part of the method result is [AssetsBundleResult.ok], the second part isn't null.
  static Future<(AssetsBundleResult, String?)> loadStringFromAssetBundle(
    String key, {
    bool cache = true,
  }) async {
    String? fileContent;

    try {
      fileContent = await rootBundle.loadString(
        key,
        cache: cache,
      );
    } catch (error) {
      // The file doesn't exist or a problem occurred
      return (AssetsBundleResult.notFound, fileContent);
    }

    return (AssetsBundleResult.ok, fileContent);
  }
}
