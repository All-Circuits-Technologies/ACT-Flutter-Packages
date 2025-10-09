// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' show Locale;

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// This mixin is used for the page or widget to set the current locale
///
/// We keep the real locale and the wanted one by the user.
mixin MixinSetWantedLocaleState<S extends MixinSetWantedLocaleState<S>> on BlocStateForMixin<S> {
  /// {@template act_intl_ui.MixinSetWantedLocaleState.currentLocale}
  /// This is the current locale of the application
  /// {@endtemplate}
  Locale get currentLocale;

  /// {@template act_intl_ui.MixinSetWantedLocaleState.wantedLocale}
  /// This is the locale wanted by the user, null if the user wants the system locale
  /// {@endtemplate}
  Locale? get wantedLocale;

  /// {@template act_intl_ui.MixinGetWantedLocaleState.copyGetWantedLocaleState}
  /// This is the copyWith method for the mixin
  /// {@endtemplate}
  S copySetWantedLocaleState({
    Locale? currentLocale,
    Locale? wantedLocale,
    bool forceWantedLocaleValue = false,
  });

  /// This method is used to copy the state with a new wanted locale
  S copyToNewCurrentLocaleState({
    required Locale currentLocale,
  }) =>
      copySetWantedLocaleState(
        currentLocale: currentLocale,
      );

  /// This method is used to copy the state with a new wanted locale
  S copyToNewLocaleWantedByUserState({
    required Locale? wantedLocale,
  }) =>
      copySetWantedLocaleState(
        wantedLocale: wantedLocale,
        forceWantedLocaleValue: true,
      );

  /// {@macro act_flutter_utility.BlocStateForMixin.props}
  @override
  List<Object?> get props => [...super.props, currentLocale, wantedLocale];
}
