// SPDX-FileCopyrightText: 2025 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_dart_utility/act_dart_utility_ext.dart';

/// Helpful class to work with Locale objects
sealed class LocaleUtility {
  /// Standard BCP47 Locale string representation uses hyphens as codes separator
  static const bcp47CodesSeparator = "-";

  /// Unicode Language Identifier, wider than BCP-47, also accepts underscore as separators
  static const underscoreSeparator = "_";

  /// Convert a [locale] to a string, using a specific [separator] to join locale codes.
  ///
  /// This function is very similar to Locale toString method, which uses an underscore separator
  /// but which is discouraged outside debug usage, and to toLanguageTag which use a hyphen
  /// separator.
  ///
  /// If you are fine with hyphen separator, you should better use toLanguageTag directly.
  ///
  /// See also [bcp47CodesSeparator] and [underscoreSeparator] constants.
  ///
  /// Note: Resulted string case is identical to toLanguageTag result case.
  static String localeToString({required Locale locale, required String separator}) =>
      locale.toLanguageTag().replaceAll(bcp47CodesSeparator, separator);

  /// Convert a Locale [string] (such as "fr_fr" or "fr-fr") to a [Locale].
  ///
  /// Locale codes [separator] can be explicitly given, see [bcp47CodesSeparator] and
  /// [underscoreSeparator] constants for common values. Both underscore and hyphen are attempted
  /// when separator is not provided therefore you likely don't need to provide it.
  ///
  /// Note that only language and optional region sub-tags are supported. Script is not supported.
  /// Note that case of resulted locale is identical to case of input string.
  static Locale localeFromString({required String string, String? separator}) {
    separator ??= string.contains(underscoreSeparator) ? underscoreSeparator : bcp47CodesSeparator;
    final subTags = string.split(separator);

    // Reminder: we only support a subset of locales
    assert(subTags.isNotEmpty && subTags.length <= 2, "Locale should have one or two sub-tags");

    final languageCode = subTags.first;
    final countryCode = subTags.length >= 2 ? subTags.last : null;
    return Locale.fromSubtags(
      languageCode: languageCode,
      countryCode: countryCode,
    );
  }

  /// Expands a single [locale] to an ordered list of supersets, starting with locales itself.
  ///
  /// For example, given fr_FR locale, generates [fr_FR, fr] ordered list which can be used
  /// to find a best matching translated resource from a user locale.
  ///
  /// Note: script sub-tag, if any, is ignored in expansions.
  static List<Locale> expandLocale(Locale locale) => expandLocales([locale]);

  /// Expands a list of [locales] by inserting their superset in the list.
  ///
  /// For example, given [fr_fr, fr_ca, en_us], generate [fr_fr, fr, fr_ca, en_us, en] which can be
  /// used to find a best matching translated resource from locales user can read.
  ///
  /// Note: script sub-tag, if any, is ignored in expansions.
  static List<Locale> expandLocales(List<Locale> locales) => locales
      // Expand each input locales to:
      .expand((locale) => [
            // Locale itself (ex: fr_FR)
            locale,
            // Locale without country sub-tag, if input locale had one (ex: fr)
            if (locale.countryCode != null) Locale(locale.languageCode),
          ])
      // Then remove duplicates, keeping order
      .toList()
      .distinct();
}
