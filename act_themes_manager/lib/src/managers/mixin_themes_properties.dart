// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';

/// This mixin is used to manage themes related properties
mixin MixinThemesProperties on AbstractPropertiesManager {
  /// This is the key used to store the current theme in the local storage.
  final currentTheme = SharedPreferencesItem<String>("CURRENT_THEME");

  /// This is the key used to store if the current theme is in light mode or not in the local
  /// storage.
  final currentThemeLightMode = SharedPreferencesItem<bool>("CURRENT_THEME_LIGHT_MODE");
}
