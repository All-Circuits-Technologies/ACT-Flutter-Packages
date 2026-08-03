// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_themes_app.dart';

void main() {
  group("MixinActThemesState.themeMode", () {
    test("shows the light theme of the application when the brightness is light", () {
      const state = FakeThemesState(currentTheme: FakeThemes.blue, brightness: Brightness.light);

      expect(state.themeMode, ThemeMode.light);
    });

    test("shows the dark theme of the application when the brightness is dark", () {
      const state = FakeThemesState(currentTheme: FakeThemes.blue, brightness: Brightness.dark);

      expect(state.themeMode, ThemeMode.dark);
    });

    test("follows the device when the application has no brightness of its own", () {
      const state = FakeThemesState(currentTheme: FakeThemes.blue);

      expect(state.themeMode, ThemeMode.system);
    });
  });

  group("MixinActThemesState.copyToNewThemeState", () {
    test("keeps the brightness of the state it copies", () {
      const state = FakeThemesState(currentTheme: FakeThemes.blue, brightness: Brightness.dark);

      final copy = state.copyToNewThemeState(currentTheme: FakeThemes.green);

      expect(copy.currentTheme, FakeThemes.green);
      expect(copy.brightness, Brightness.dark);
    });
  });

  group("MixinActThemesState.copyToNewBrightnessState", () {
    test("keeps the theme of the state it copies", () {
      const state = FakeThemesState(currentTheme: FakeThemes.green, brightness: Brightness.dark);

      final copy = state.copyToNewBrightnessState(brightness: Brightness.light);

      expect(copy.currentTheme, FakeThemes.green);
      expect(copy.brightness, Brightness.light);
    });

    test("gives back the brightness of the device", () {
      const state = FakeThemesState(currentTheme: FakeThemes.green, brightness: Brightness.dark);

      final copy = state.copyToNewBrightnessState(brightness: null);

      expect(copy.brightness, isNull);
    });
  });

  group("MixinActThemesState", () {
    test("is the same state as another one which shows the same theme", () {
      expect(
        const FakeThemesState(currentTheme: FakeThemes.blue, brightness: Brightness.dark),
        const FakeThemesState(currentTheme: FakeThemes.blue, brightness: Brightness.dark),
      );
    });

    test("is another state as soon as the brightness differs", () {
      expect(
        const FakeThemesState(currentTheme: FakeThemes.blue, brightness: Brightness.dark),
        isNot(const FakeThemesState(currentTheme: FakeThemes.blue)),
      );
    });
  });
}
