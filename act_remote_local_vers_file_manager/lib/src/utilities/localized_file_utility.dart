// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:ui';

import 'package:act_intl/act_intl.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_remote_local_vers_file_manager/src/constants/remote_local_vers_file_constants.dart'
    as server_local_vers_file_constants;
import 'package:act_remote_local_vers_file_manager/src/utilities/variant_file_utility.dart';
import 'package:act_remote_storage_manager/act_remote_storage_manager.dart';
import 'package:flutter/rendering.dart';

/// This pseudo-class contains localized file helper static functions.
///
/// {@template act_remote_local_vers_file_manager.LocalizedFileUtility.serverRequirements}
/// Localized files are expected to follow a specific filesystem layout:
/// - Any localized file must be handled within a dedicated folder
/// - Such folder must contain one sub-folder per locale, joined with underscore and lowercase
/// - Wanted file must exist in all local sub-folders, with the same name
///
/// Example:
/// - my_file/fr_fr/my_file.md
/// - my_file/fr/my_file.md
/// - my_file/en_us/my_file.md
/// {@endtemplate}
sealed class LocalizedFileUtility {
  /// Search localized [fileName] in [dirId] of [storage].
  ///
  /// That is, find first [dirId]/$locale/[fileName] based on sorted [locales],
  /// with $locale in "en_us" format (underscore, lowercase).
  static Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String filePath, File file})? data,
      })> getLocalizedFile({
    required AbsRemoteStorageManager storage,
    required String dirId,
    required String fileName,
    required List<Locale> locales,
    required bool useCache,
    required LogsHelper logsHelper,
  }) async {
    // Convert locales to variants, keeping the locale each variant was written from: variants are
    // lowercase, so reading one back as a locale would give a locale which differs from the one
    // the caller asked for (ex: "fr_fr" instead of "fr_FR").
    final expandedLocales = LocaleUtility.expandLocales(locales);

    final localesByVariant = {
      for (final locale in expandedLocales)
        LocaleUtility.localeToString(
          locale: locale,
          separator: server_local_vers_file_constants.localeCodesSep,
        ).toLowerCase(): locale,
    };

    // Process lookup with variants
    final variantUtilityResult = await VariantFileUtility.getVariantFile(
      storage: storage,
      variants: localesByVariant.keys,
      variantToFilePath: (variant) => [dirId, variant, fileName].join(storage.getPathSeparator()),
      useCache: useCache,
      logsHelper: logsHelper,
    );

    if (variantUtilityResult.result != StorageRequestResult.success) {
      return (result: variantUtilityResult.result, data: null);
    }

    if (variantUtilityResult.data == null) {
      logsHelper.e("A successful variant file utility result should always have a valid data");
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, data: null);
    }

    // Transform result back to locales
    final foundVariant = variantUtilityResult.data!.variant;
    final foundLocale = localesByVariant[foundVariant];

    if (foundLocale == null) {
      // We searched the file with the variants we stringified from the given locales, so the
      // variant which was found is one of them.
      // We do not expect any issue here.
      logsHelper.e("Variants are stringified locales, so should be known as locales again");
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, data: null);
    }

    return (
      result: variantUtilityResult.result,
      data: (
        locale: foundLocale,
        filePath: variantUtilityResult.data!.filePath,
        file: variantUtilityResult.data!.file,
      ),
    );
  }
}
