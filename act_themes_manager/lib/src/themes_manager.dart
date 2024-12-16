// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/material.dart';

/// This is the appendix them which can be added to the ColorTheme
abstract class AppendixTheme {
  /// Class constructor
  AppendixTheme();
}

/// This is the color theme to use
class ColorTheme<ApxTheme extends AppendixTheme> {
  /// The theme data linked to this color theme
  final ThemeData themeData;

  /// This allows to define extra theme information, and to not forget them when defining multiple
  /// themes
  final ApxTheme? otherElem;

  /// Class constructor
  ColorTheme({
    required this.themeData,
    this.otherElem,
  });
}

/// This is the builder to create the [ThemesManager] class
class ThemesBuilder<T, ApxTheme extends AppendixTheme>
    extends ManagerBuilder<ThemesManager<T, ApxTheme>> {
  /// Class constructor
  ThemesBuilder({
    required Map<T, ColorTheme<ApxTheme>> availableThemes,
    required T currentTheme,
  }) : super(() => ThemesManager(
              availableThemes: availableThemes,
              currentTheme: currentTheme,
            ));

  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// The main application theme
class ThemesManager<T, ApxTheme extends AppendixTheme> extends AbstractManager {
  /// This contains the themes depending of the current context
  final Map<T, ColorTheme<ApxTheme>> _availableThemes;

  /// This is the current context
  T _currentTheme;

  /// Get the current context
  T get currentTheme => _currentTheme;

  /// Class constructor
  ThemesManager({
    required Map<T, ColorTheme<ApxTheme>> availableThemes,
    required T currentTheme,
  })  : _availableThemes = availableThemes,
        _currentTheme = currentTheme,
        super();

  /// Get the main theme
  ColorTheme<ApxTheme> getMain() {
    return _availableThemes[_currentTheme]!;
  }

  /// Init the manager
  @override
  Future<void> initManager() async {}
}
