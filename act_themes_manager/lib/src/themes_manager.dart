// Copyright (c) 2020. BMS Circuits

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/material.dart';

class ThemeChoice<T> {
  final T value;

  ThemeChoice({
    @required this.value,
  }) : assert(value != null);
}

abstract class AppendixTheme {
  AppendixTheme();
}

class ColorTheme {
  final ThemeData themeData;
  final AppendixTheme otherElem;

  ColorTheme({
    @required this.themeData,
    this.otherElem,
  }) : assert(themeData != null);
}

class ThemesBuilder<T> extends ManagerBuilder<ThemesManager> {
  ThemesBuilder({
    Map<ThemeChoice, ColorTheme> availableThemes,
    ThemeChoice currentTheme,
  }) : super(() => ThemesManager(
              availableThemes: availableThemes,
              currentTheme: currentTheme,
            ));

  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// The main application theme
class ThemesManager<T> extends AbstractManager {
  final Map<ThemeChoice<T>, ColorTheme> _availableThemes;

  ThemeChoice<T> _currentTheme;

  ThemeChoice get currentTheme => _currentTheme;

  ThemesManager({
    @required Map<ThemeChoice, ColorTheme> availableThemes,
    @required ThemeChoice currentTheme,
  })  : assert(availableThemes != null),
        assert(currentTheme != null),
        _availableThemes = availableThemes,
        _currentTheme = currentTheme,
        super();

  ColorTheme getMain() {
    return _availableThemes[_currentTheme];
  }

  @override
  Future<void> initManager() async => null;
}
