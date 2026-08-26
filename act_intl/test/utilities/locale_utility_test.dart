// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_intl/act_intl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("LocaleUtility.localeToString", () {
    test("writes a locale the way a language tag is written", () {
      expect(LocaleUtility.localeToString(locale: const Locale("fr", "FR")), "fr-FR");
    });

    test("writes a locale with the separator it is given", () {
      expect(
        LocaleUtility.localeToString(
          locale: const Locale("fr", "FR"),
          separator: LocaleUtility.underscoreSeparator,
        ),
        "fr_FR",
      );
    });

    test("writes a locale which has no country", () {
      expect(
        LocaleUtility.localeToString(
          locale: const Locale("fr"),
          separator: LocaleUtility.underscoreSeparator,
        ),
        "fr",
      );
    });
  });

  group("LocaleUtility.localeFromString", () {
    test("reads a locale written with a hyphen", () {
      expect(LocaleUtility.localeFromString(string: "fr-FR"), const Locale("fr", "FR"));
    });

    test("reads a locale written with an underscore", () {
      expect(LocaleUtility.localeFromString(string: "fr_FR"), const Locale("fr", "FR"));
    });

    test("reads a locale which has no country", () {
      expect(LocaleUtility.localeFromString(string: "fr"), const Locale("fr"));
    });

    test("reads a locale with the separator it is given", () {
      expect(
        LocaleUtility.localeFromString(
          string: "fr_FR",
          separator: LocaleUtility.underscoreSeparator,
        ),
        const Locale("fr", "FR"),
      );
    });

    test("keeps the case of the string it is given", () {
      expect(LocaleUtility.localeFromString(string: "fr-fr")?.countryCode, "fr");
    });

    test("reads nothing from an empty string", () {
      expect(LocaleUtility.localeFromString(string: ""), isNull);
    });

    test("reads nothing with an empty separator", () {
      expect(LocaleUtility.localeFromString(string: "fr-FR", separator: ""), isNull);
    });

    test("reads nothing from a locale which has more sub tags than it supports", () {
      expect(LocaleUtility.localeFromString(string: "zh-Hans-CN"), isNull);
    });

    test("reads the whole string when it holds no separator of its own", () {
      expect(
        LocaleUtility.localeFromString(
          string: "fr-FR",
          separator: LocaleUtility.underscoreSeparator,
        ),
        const Locale("fr-FR"),
      );
    });
  });

  group("LocaleUtility.expandLocale", () {
    test("expands a locale into itself and the language it belongs to", () {
      expect(LocaleUtility.expandLocale(const Locale("fr", "FR")), [
        const Locale("fr", "FR"),
        const Locale("fr"),
      ]);
    });

    test("leaves a locale which has no country alone", () {
      expect(LocaleUtility.expandLocale(const Locale("fr")), [const Locale("fr")]);
    });
  });

  group("LocaleUtility.expandLocales", () {
    test("expands every locale it is given, in the order it is given", () {
      final locales = LocaleUtility.expandLocales(const [
        Locale("fr", "FR"),
        Locale("fr", "CA"),
        Locale("en", "US"),
      ]);

      expect(locales, const [
        Locale("fr", "FR"),
        Locale("fr"),
        Locale("fr", "CA"),
        Locale("en", "US"),
        Locale("en"),
      ]);
    });

    test("keeps a language which several locales expand into only once", () {
      final locales = LocaleUtility.expandLocales(const [Locale("fr", "FR"), Locale("fr")]);

      expect(locales, const [Locale("fr", "FR"), Locale("fr")]);
    });

    test("expands an empty list into an empty one", () {
      expect(LocaleUtility.expandLocales([]), isEmpty);
    });
  });
}
