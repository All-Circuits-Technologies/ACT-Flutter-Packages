// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:io';
import 'dart:ui';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_server_local_vers_file_manager/src/utilities/variant_file_utility.dart';
import 'package:act_server_storage_manager/act_server_storage_manager.dart';
import 'package:flutter/rendering.dart';

/// This pseudo-class contains localized file helper static functions.
///
/// Localized files are expected to follow a specific filesystem layout:
/// - Any localized file must be handled within a dedicated folder
/// - Such folder must contain one sub-folder per locale, joined with underscore and lowercase
/// - Wanted file must exist in all local sub-folders, with the same name
///
/// Example:
/// - my_file/fr_fr/my_file.md
/// - my_file/fr/my_file.md
/// - my_file/en_us/my_file.md
sealed class LocalizedFileUtility {
  /// We use underscores as locale codes separator.
  /// Ex: American english locale variant would be named "en_us".
  static const _localeCodesSep = "_";

  /// Storage is expected to support folders, with this separator
  // TODO(aloiseau): get path separator from the storage service
  static const _pathSep = "/";

  /// Search localized [fileName] in [dirId] of [storage].
  ///
  /// That is, find first [dirId]/locale/[fileName] based on sorted [locales],
  /// with locale in "en_us" format (underscore, lowercase).
  static Future<
      ({
        StorageRequestResult result,
        ({Locale locale, String filePath, File file})? data,
      })> getLocalizedFile({
    required AbsServerStorageManager storage,
    required String dirId,
    required String fileName,
    required List<Locale> locales,
    required bool useCache,
  }) async {
    // Convert locales to variants.
    final expandedLocales = LocaleUtility.expandLocales(locales);

    final variants = expandedLocales.map((locale) => LocaleUtility.localeToString(
          locale: locale,
          separator: _localeCodesSep,
        ).toLowerCase());

    // Process lookup with variants
    final variantUtilityResult = await VariantFileUtility.getVariantFile(
      storage: storage,
      variants: variants,
      variantToFilePath: (variant) => "$dirId$_pathSep$variant$_pathSep$fileName",
      useCache: useCache,
    );

    if (variantUtilityResult.result != StorageRequestResult.success) {
      return (result: variantUtilityResult.result, data: null);
    }

    if (variantUtilityResult.data == null) {
      assert(false, "Should never fire");
      return (result: StorageRequestResult.genericError, data: null);
    }

    // Transform result back to locales
    final foundVariant = variantUtilityResult.data!.variant;
    final foundLocale = LocaleUtility.localeFromString(
      string: foundVariant,
      separator: _localeCodesSep,
    );

    if (foundLocale == null) {
      // We stringified locales at the very beginning of this method
      // and we transformed one of them back to a locale.
      // We do not expect any issue here.
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
