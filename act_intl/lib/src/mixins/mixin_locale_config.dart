// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';

/// This mixin is used to manage locale related config variables
mixin MixinLocaleConfig on AbstractConfigManager {
  /// This is the config variable used to set the default wanted locale, which is used when there
  /// is no wanted locale stored in the local storage.
  ///
  /// This may be null if you want to use the system locale as the default wanted locale.
  ///
  /// This allows to have a different default wanted locale depending on the config env
  /// (e.g. "en" for the "prod" env and "fr" for the "dev" env).
  ///
  /// The language code should be in the format of "languageCode-countryCode", for example "en-US"
  /// or "fr-FR".
  final defaultWantedLocale = const ConfigVar<String>("locale.defaultWanted");

  /// This is the config variable used to force the wanted locale in dev mode.
  ///
  /// If true, it means that, in dev only, we use the [defaultWantedLocale] even if there is a
  /// wanted locale stored in the local storage.
  /// This is useful to test the app with different locales without having to clear the local
  /// storage each time we want to change the locale.
  ///
  /// This has no effect if [defaultWantedLocale] is null, since there is no default wanted locale
  /// to use.
  final forceWantedLocaleInDev = const NotNullableConfigVar<bool>(
    "locale.dev.forceWanted",
    defaultValue: false,
  );
}
