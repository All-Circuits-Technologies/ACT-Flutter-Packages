// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';

import 'package:act_server_storage_manager/act_server_storage_manager.dart';

/// This pseudo-class contains variant file helper static functions.
///
/// Variant files are files to search through one of their possible names, in a specific order.
/// It is for example possible to search for a given file with extensions among ["md", "txt"],
/// or for a given file under sub-folders among ["fr_fr", "en_us"].
///
/// Note that LocalizedFileUtility uses [VariantFileUtility] as its backend.
/// You may want to use LocalizedFileUtility if your goal is to play with locales variants.
sealed class VariantFileUtility {
  /// Get a file from [storage], whose path may vary among [variants] values and is computed using
  /// [variantToFilePath]. Fetched file is cached locally if [useCache] is true (storage feature).
  static Future<
      ({
        StorageRequestResult result,
        ({String variant, String filePath, File file})? data,
      })> getVariantFile({
    required AbsServerStorageManager storage,
    required Iterable<String> variants,
    required String Function(String) variantToFilePath,
    required bool useCache,
  }) async {
    StorageRequestResult? firstError;

    for (final variant in variants) {
      final variantPath = variantToFilePath(variant);
      final fetchResult = await storage.getFile(variantPath, useCache: useCache);

      if (fetchResult.result == StorageRequestResult.success && fetchResult.file != null) {
        return (
          result: fetchResult.result,
          data: (
            variant: variant,
            filePath: variantPath,
            file: fetchResult.file!,
          ),
        );
      }

      // Save best attempt error to return it if no variants can be found
      firstError ??= fetchResult.result;
    }

    // Failed to find file in any variant
    return (
      result: firstError ?? StorageRequestResult.genericError,
      data: null,
    );
  }
}
