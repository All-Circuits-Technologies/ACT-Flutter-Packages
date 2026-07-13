// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_dart_value_keeper/act_dart_value_keeper.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_themes_manager/src/managers/mixin_themes_config.dart';
import 'package:act_themes_manager/src/managers/mixin_themes_properties.dart';
import 'package:act_themes_manager/src/models/act_themes_not_defined.dart';
import 'package:act_themes_manager/src/types/mixin_act_themes.dart';
import 'package:flutter/widgets.dart' show Brightness;

/// This is the builder of the [ActThemesManager] class.
class ActThemesBuilder<C extends MixinThemesConfig, P extends MixinThemesProperties>
    extends AbsLifeCycleFactory<ActThemesManager> {
  /// Class constructor
  ActThemesBuilder({required List<MixinActThemes> appThemes})
    : super(
        () => ActThemesManager(
          propertiesGetter: () => globalGetIt().get<P>(),
          configGetter: () => globalGetIt().get<C>(),
          appThemes: appThemes,
        ),
      );

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager, P, C];
}

/// This manager is used to manage the themes of the application. It contains the themes of the
/// application and the logic to switch between them.
///
/// It also contains the logic to save the current theme in the local storage and to get it from
/// the local storage when the application is launched.
///
/// The light mode of the application is also managed by this manager, with the same logic as the
/// theme.
/// The default light mode is retrieved from the system default value.
class ActThemesManager extends AbsWithLifeCycleAndUi {
  /// The log category of the manager
  static const String _logCategory = "themes";

  /// This function is used to get the properties manager
  final MixinThemesProperties Function() _propertiesGetter;

  /// This function is used to get the config manager
  final MixinThemesConfig Function() _configGetter;

  /// The themes of the application.
  final List<MixinActThemes> appThemes;

  /// The current theme of the application with stream
  late final ValueKeeperWithStream<MixinActThemes> _currentTheme;

  /// The current brightness mode of the application with stream
  late final ValueKeeperWithStream<Brightness?> _brightness;

  /// This is the helper used to log messages
  late final LogsHelper _logsHelper;

  /// Get the current theme of the application.
  MixinActThemes get currentTheme => _currentTheme.value;

  /// Get the current theme of the application as a stream.
  Stream<MixinActThemes> get currentThemeStream => _currentTheme.valueStream;

  /// Get the current brightness mode of the application.
  ///
  /// If null, it means that the system default brightness mode should be used.
  Brightness? get brightness => _brightness.value;

  /// Get the current brightness mode of the application as a stream.
  ///
  /// If the stream emits null, it means that the system default brightness mode should be used.
  Stream<Brightness?> get brightnessStream => _brightness.valueStream;

  /// Class constructor
  ActThemesManager({
    required MixinThemesProperties Function() propertiesGetter,
    required MixinThemesConfig Function() configGetter,
    required this.appThemes,
  }) : _propertiesGetter = propertiesGetter,
       _configGetter = configGetter {
    if (appThemes.isEmpty) {
      throw ActThemesNotDefinedError();
    }
  }

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _logsHelper = LogsHelper(category: _logCategory);

    final defaultTheme = await _getCurrentTheme();
    _currentTheme = ValueKeeperWithStream(value: defaultTheme);

    final defaultBrightness = await _getCurrentBrightness();
    _brightness = ValueKeeperWithStream(value: defaultBrightness);
  }

  /// This method is used to update the current theme of the application, and save it in the local
  /// storage.
  Future<void> setCurrentTheme({required MixinActThemes newTheme}) async {
    if (!appThemes.contains(newTheme)) {
      _logsHelper.w(
        "The theme $newTheme does not match any of the themes defined in the appThemes list, "
        "ignoring the update.",
      );
      return;
    }

    _currentTheme.value = newTheme;
    await _propertiesGetter().currentTheme.store(newTheme.stringValue);
  }

  /// This method is used to update the current brightness mode of the application, and save it in
  /// the local storage.
  Future<void> setBrightness({required Brightness? newBrightness}) async {
    _brightness.value = newBrightness;

    bool? isLightMode;
    if (newBrightness != null) {
      isLightMode = newBrightness == Brightness.light;
    }
    await _propertiesGetter().currentThemeLightMode.store(isLightMode);
  }

  /// Get the current theme of the application, either from the config or from the local storage.
  Future<MixinActThemes> _getCurrentTheme() async {
    final config = _configGetter();

    var defaultThemeStr = config.defaultTheme.load();
    final forceThemeInDev = config.env == Environment.development && config.forceThemeInDev.load();

    if (defaultThemeStr == null || !forceThemeInDev) {
      final tmpStoredTheme = await _propertiesGetter().currentTheme.load();
      if (tmpStoredTheme != null) {
        // If there is no stored theme, we want to use the default theme defined in the config
        defaultThemeStr = tmpStoredTheme;
      }
    }

    if (defaultThemeStr == null) {
      // Because we throw an error in the class constructor if there is no theme defined in the
      // appThemes list, we can be sure that there is at least one theme in the list, so we can
      // return the first one as the default theme.
      _logsHelper.d(
        "No default theme defined, using the first theme of the appThemes list as the "
        "default theme.",
      );
      return appThemes.first;
    }

    final defaultTheme = MixinStringValueType.tryToParseFromStringValue<MixinActThemes>(
      value: defaultThemeStr,
      values: appThemes,
    );
    if (defaultTheme == null) {
      _logsHelper.w(
        "The default theme defined in the config does not match any of the themes defined in "
        "the appThemes list, using the first theme of the appThemes list as the default theme.",
      );
      return appThemes.first;
    }

    return defaultTheme;
  }

  /// Get the current brightness mode of the application, either from the config or from the local
  /// storage, or from the system default value.
  ///
  /// If the returned value is null, it means that the system default brightness mode should be
  /// used.
  Future<Brightness?> _getCurrentBrightness() async {
    final config = _configGetter();

    final forceLightModeInDevValue = config.env == Environment.development
        ? config.forceLightModeInDevValue.load()
        : null;

    if (forceLightModeInDevValue != null) {
      return forceLightModeInDevValue ? Brightness.light : Brightness.dark;
    }

    final isLightMode = await _propertiesGetter().currentThemeLightMode.load();
    if (isLightMode == null) {
      _logsHelper.d(
        "No light mode value defined in the local storage, using the system default brightness.",
      );

      return null;
    }

    return isLightMode ? Brightness.light : Brightness.dark;
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _currentTheme.disposeLifeCycle();
    await _brightness.disposeLifeCycle();

    return super.disposeLifeCycle();
  }
}
