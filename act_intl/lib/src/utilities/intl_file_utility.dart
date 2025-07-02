// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Contains helper methods to manage files
class IntlFileUtility {
  /// This method allow to load an asset file which contains translated text
  ///
  /// The [path] given is the raw path without the language tag. Thanks to the
  /// [context] given to the method, the method will get the current language and
  /// try to load the file with the right translation.
  ///
  /// If the file can't be found with the current language, the method tries to
  /// find a file with the the default language (en_US)
  ///
  /// If nothing is found, it returns null
  ///
  /// Ex: if you give the path file: 'assets/texts/readme.me' and if the current
  /// language is 'fr_FR'.
  /// The method tries to find the file: 'assets/texts/readme_fr_FR.me'
  /// If it doesn't find it, it will try: 'assets/texts/readme_en_US.me'
  static Future<String?> loadTransAssetFileText(
    BuildContext context,
    String path,
  ) async {
    final myLocale = Localizations.localeOf(context);
    final localName = Intl.canonicalizedLocale(myLocale.toLanguageTag());

    final dotIndex = path.indexOf(".");

    final startPath = "${path.substring(0, dotIndex)}_";
    final endPath = path.substring(dotIndex);

    String? translated;

    try {
      translated = await DefaultAssetBundle.of(context)
          .loadString(startPath + localName + endPath);
    } catch (_) {
      appLogger().w("Cannot found the file: $startPath$localName$endPath, try "
          "to load the file: $startPath${Intl.systemLocale}$endPath");
    }

    if (translated == null) {
      try {
        // The context won't be changed while the method is processed; therefore it's ok
        // ignore: use_build_context_synchronously
        translated = await DefaultAssetBundle.of(context)
            .loadString(startPath + Intl.systemLocale + endPath);
      } catch (_) {
        appLogger().w("Cannot found the file: "
            "$startPath${Intl.systemLocale}$endPath");
      }
    }

    return translated;
  }
}
