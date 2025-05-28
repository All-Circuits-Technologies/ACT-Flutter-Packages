// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_dart_utility/act_dart_utility_ext.dart';

/// Helpful class to work with Locale objects
sealed class LocaleUtility {
  /// Standard BCP47 Locale string representation uses hyphens as codes separator
  static const bcp47CodesSeparator = "-";

  /// Convert a [locale] to a string, using a specific [separator] to join locale codes.
  ///
  /// This function is very similar to Locale toString method, which uses an underscore separator
  /// but which is discouraged outside debug usage, and to toLanguageTag which use a hyphen
  /// separator.
  ///
  /// If you are fine with hyphen separator, you should better use toLanguageTag directly.
  ///
  /// Note: Resulted string case is identical to toLanguageTag result case.
  static String localeToString({required Locale locale, required String separator}) =>
      locale.toLanguageTag().replaceAll(bcp47CodesSeparator, separator);

  /// Convert a Locale [string] (such as "fr_fr" or "fr-fr") to a [Locale].
  ///
  /// Locale codes [separator] can be explicitly given. Both underscore and hyphen are attempted
  /// when separator is not provided.
  /// Note that case of resulted locale is identical to case of input string.
  static Locale localeFromString({required String string, String? separator}) {
    separator ??= string.contains('_') ? '_' : '-';
    final subTags = string.split(separator);
    assert(subTags.isNotEmpty && subTags.length <= 3, "Locale should have one to three sub-tags");

    final languageCode = subTags.first;
    final countryCode = subTags.length >= 2 ? subTags.last : null;
    final scriptCode = subTags.length >= 3 ? subTags.elementAt(1) : null;
    return Locale.fromSubtags(
      languageCode: languageCode,
      scriptCode: scriptCode,
      countryCode: countryCode,
    );
  }

  /// Expands a single [locale] to a list of locales.
  ///
  /// Given a single locale, such as fr_fr, generates a list of locales such as [fr_fr, fr].
  static List<Locale> expandLocale(Locale locale) => expandLocales([locale]);

  /// Expands a list of [locales].
  ///
  /// Given a small list of locales, such as [fr_fr, fr_ca, en_us], generate a longer list of locals
  /// such as [fr_fr, fr, fr_ca, en_us, en].
  ///
  /// Note: script sub-tags, if any, are ignored in expansions.
  static List<Locale> expandLocales(List<Locale> locales) => locales
      // Expand each input locales to:
      .expand((locale) => [
            // Locale itself
            locale,
            // Locale without script sub-tag if input locale had one (ex: fr_FR)
            if (locale.scriptCode != null) Locale(locale.languageCode, locale.countryCode),
            // Locale without script and country sub-tags, if input locale had them (ex: fr)
            if (locale.countryCode != null) Locale(locale.languageCode),
          ])
      // Then remove duplicates, keeping order
      .toList()
      .distinct();
}
