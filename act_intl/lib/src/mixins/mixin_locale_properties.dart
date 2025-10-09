// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';

/// This mixin is used to manage locale related properties
mixin MixinLocaleProperties on AbstractPropertiesManager {
  /// This is the key used to store the wanted locale in the local storage
  final wantedLocale = SharedPreferencesItem<String>("WANTED_LANG");
}
