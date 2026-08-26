// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' show Locale;

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_intl_ui/act_intl_ui.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The locales the application under test is translated in.
const supportedLocales = [Locale("fr", "FR"), Locale("en", "GB")];

/// The configuration of the application under test.
class FakeLocaleConfig extends AbstractConfigManager with MixinLocaleConfig {
  /// Class constructor
  FakeLocaleConfig() : super(logger: const SilentLogger());
}

/// The properties of the application under test, which keep the locale the user chose.
class FakeLocaleProperties extends AbstractPropertiesManager with MixinLocaleProperties {}

/// The locales of the application under test.
///
/// The blocs of this package read the locales of an application from its locales manager, so a test
/// needs a real one, over a configuration and a storage of its own.
class FakeLocalesApp {
  /// The manager the application reads its locales from.
  final LocalesManager manager;

  /// The configuration the locales are read from.
  final FakeLocaleConfig config;

  /// Class constructor
  const FakeLocalesApp({required this.manager, required this.config});

  /// Builds the locales manager of an application and registers it in [globalManager].
  static Future<FakeLocalesApp> install(
    FakeGlobalManager globalManager, {
    String? storedLocale,
  }) async {
    FakeAssets.serve({"assets/config/default.yaml": "locale:\n  dev:\n    forceWanted: false"});

    final config = FakeLocaleConfig();
    await config.initLifeCycle();

    final properties = FakeLocaleProperties();
    await properties.initLifeCycle();
    await properties.deleteAll();
    if (storedLocale != null) {
      await properties.wantedLocale.store(storedLocale);
    }

    final manager = LocalesManager(
      getSupportedLocales: () => supportedLocales,
      propertiesGetter: () => properties,
      configGetter: () => config,
    );
    await manager.initLifeCycle();
    globalManager.managers.registerSingleton<LocalesManager>(manager);

    return FakeLocalesApp(manager: manager, config: config);
  }

  /// Forgets the locales of the application.
  ///
  /// The configuration of an application is a singleton, so a test which built one has to forget it
  /// before the next test builds its own.
  Future<void> dispose() async {
    await manager.disposeLifeCycle();
    await config.disposeLifeCycle();
  }
}

/// The state of the page of the application under test.
class FakeLocaleState extends BlocStateForMixin<FakeLocaleState>
    with MixinGetWantedLocaleState<FakeLocaleState>, MixinSetWantedLocaleState<FakeLocaleState> {
  /// {@macro act_intl_ui.MixinSetWantedLocaleState.currentLocale}
  @override
  final Locale currentLocale;

  /// {@macro act_intl_ui.MixinGetWantedLocaleState.wantedLocale}
  @override
  final Locale? wantedLocale;

  /// Class constructor
  const FakeLocaleState({this.currentLocale = const Locale("en", "GB"), this.wantedLocale});

  /// {@macro act_flutter_utility.BlocStateForMixin.copyWith}
  @override
  FakeLocaleState copyWith({Locale? currentLocale, Locale? wantedLocale}) => FakeLocaleState(
    currentLocale: currentLocale ?? this.currentLocale,
    wantedLocale: wantedLocale ?? this.wantedLocale,
  );

  /// {@macro act_intl_ui.MixinGetWantedLocaleState.copyGetWantedLocaleState}
  @override
  FakeLocaleState copyGetWantedLocaleState({
    Locale? wantedLocale,
    bool forceWantedLocaleValue = false,
  }) => FakeLocaleState(
    currentLocale: currentLocale,
    wantedLocale: wantedLocale ?? (forceWantedLocaleValue ? null : this.wantedLocale),
  );

  /// {@macro act_intl_ui.MixinGetWantedLocaleState.copyGetWantedLocaleState}
  @override
  FakeLocaleState copySetWantedLocaleState({
    Locale? currentLocale,
    Locale? wantedLocale,
    bool forceWantedLocaleValue = false,
  }) => FakeLocaleState(
    currentLocale: currentLocale ?? this.currentLocale,
    wantedLocale: wantedLocale ?? (forceWantedLocaleValue ? null : this.wantedLocale),
  );
}

/// The bloc of a page which follows the locale the user chose.
class FakeGetLocaleBloc extends BlocForMixin<FakeLocaleState>
    with MixinGetWantedLocaleBloc<FakeLocaleState> {
  /// Class constructor
  FakeGetLocaleBloc() : super(const FakeLocaleState());
}

/// The bloc of a page which lets the user choose the locale.
class FakeSetLocaleBloc extends BlocForMixin<FakeLocaleState>
    with MixinSetWantedLocaleBloc<FakeLocaleState> {
  /// Class constructor
  FakeSetLocaleBloc() : super(const FakeLocaleState());
}
