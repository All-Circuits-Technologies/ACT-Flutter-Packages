// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_themes_manager/act_themes_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_themes_app.dart';

/// The colors of the light theme of an application.
final _lightColors = ActThemeColors<FakeSpecificColors>(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
  colorExtensions: const FakeSpecificColors(highlight: Colors.amber),
);

/// The colors of the dark theme of an application.
final _darkColors = ActThemeColors<FakeSpecificColors>(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
);

void main() {
  group("ActThemeModel", () {
    test("builds the theme of an application which is only light", () {
      final model = ActThemeModel<FakeSpecificColors>(lightColors: _lightColors);

      expect(model.lightThemeData?.brightness, Brightness.light);
      expect(model.darkThemeData, isNull);
    });

    test("builds the theme of an application which is only dark", () {
      final model = ActThemeModel<FakeSpecificColors>(darkColors: _darkColors);

      expect(model.darkThemeData?.brightness, Brightness.dark);
      expect(model.lightThemeData, isNull);
    });

    test("builds both themes of an application which has the two", () {
      final model = ActThemeModel<FakeSpecificColors>(
        lightColors: _lightColors,
        darkColors: _darkColors,
      );

      expect(model.lightThemeData, isNotNull);
      expect(model.darkThemeData, isNotNull);
    });

    test("refuses to build a theme which has neither light nor dark colors", () {
      expect(ActThemeModel<FakeSpecificColors>.new, throwsAssertionError);
    });

    test("paints with the colors it was given", () {
      final model = ActThemeModel<FakeSpecificColors>(lightColors: _lightColors);

      expect(model.lightThemeData?.colorScheme, _lightColors.colorScheme);
    });

    test("carries the colors the application added to the ones of the scheme", () {
      final model = ActThemeModel<FakeSpecificColors>(lightColors: _lightColors);

      expect(
        model.lightThemeData?.extension<FakeSpecificColors>()?.highlight,
        Colors.amber,
      );
    });

    test("writes with the font the application asked for", () {
      final model = ActThemeModel<FakeSpecificColors>(
        lightColors: _lightColors,
        fontFamily: "aFont",
      );

      expect(model.lightThemeData?.textTheme.bodyMedium?.fontFamily, "aFont");
    });

    test("takes the text theme the application overrides", () {
      final model = ActThemeModel<FakeSpecificColors>(
        lightColors: _lightColors,
        overrideDefaultTextTheme: ({required baseThemeData}) =>
            baseThemeData.textTheme.copyWith(bodyMedium: const TextStyle(fontSize: 42)),
      );

      expect(model.lightThemeData?.textTheme.bodyMedium?.fontSize, 42);
    });

    test("takes the theme data the application overrides", () {
      final model = ActThemeModel<FakeSpecificColors>(
        lightColors: _lightColors,
        overrideDefaultThemeData: ({required baseThemeData}) =>
            baseThemeData.copyWith(splashFactory: NoSplash.splashFactory),
      );

      expect(model.lightThemeData?.splashFactory, NoSplash.splashFactory);
    });

    test("overrides the theme data from the one the text theme was written in", () {
      final model = ActThemeModel<FakeSpecificColors>(
        lightColors: _lightColors,
        overrideDefaultTextTheme: ({required baseThemeData}) =>
            baseThemeData.textTheme.copyWith(bodyMedium: const TextStyle(fontSize: 42)),
        overrideDefaultThemeData: ({required baseThemeData}) => baseThemeData.copyWith(
          primaryTextTheme: baseThemeData.textTheme,
        ),
      );

      expect(model.lightThemeData?.primaryTextTheme.bodyMedium?.fontSize, 42);
    });

    test("is the same theme as another one built from the same colors", () {
      expect(
        ActThemeModel<FakeSpecificColors>(lightColors: _lightColors),
        ActThemeModel<FakeSpecificColors>(lightColors: _lightColors),
      );
    });
  });
}
