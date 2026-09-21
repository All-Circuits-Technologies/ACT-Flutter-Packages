// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// This class loads the raw content of the config assets from the assets bundle.
///
/// The config files are yaml or json files. When the file type isn't part of the key, the loader
/// tries the known file types, in order.
sealed class ConfigAssetLoader {
  /// This is the separator between the file name and its type.
  static const _fileTypeSeparator = ".";

  /// The file types the loader tries, in order, to find a config or a mapping file.
  static const _fileTypes = ["yaml", "yml", "json"];

  /// Load the raw content of the asset named [key], trying the [_fileTypes] in order.
  ///
  /// The method returns the content of the first file found, or null when none exists.
  static Future<String?> loadRaw(String key) async {
    for (final type in _fileTypes) {
      final result = await AssetsBundleUtility.loadStringFromAssetBundle(
        "$key$_fileTypeSeparator$type",
        cache: false,
      );

      if (result.status == AssetsBundleResult.ok) {
        return result.value;
      }
    }

    return null;
  }
}
