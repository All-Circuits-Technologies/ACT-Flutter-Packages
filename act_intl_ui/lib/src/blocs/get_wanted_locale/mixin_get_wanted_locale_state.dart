// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' show Locale;

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// This mixin is used for the main app state, to get the wanted locale set by the user
mixin MixinGetWantedLocaleState<S extends MixinGetWantedLocaleState<S>> on BlocStateForMixin<S> {
  /// {@template act_intl_ui.MixinGetWantedLocaleState.wantedLocale}
  /// This is the locale wanted by the user, null if the user wants the system locale
  /// {@endtemplate}
  Locale? get wantedLocale;

  /// {@template act_intl_ui.MixinGetWantedLocaleState.copyGetWantedLocaleState}
  /// This is the copyWith method for the mixin
  /// {@endtemplate}
  S copyGetWantedLocaleState({
    Locale? wantedLocale,
    bool forceWantedLocaleValue = false,
  });

  /// This method is used to copy the state with a new wanted locale
  S copyToNewLocaleWantedByUserState({
    required Locale? wantedLocale,
  }) =>
      copyGetWantedLocaleState(
        wantedLocale: wantedLocale,
        forceWantedLocaleValue: true,
      );

  /// {@macro act_flutter_utility.BlocStateForMixin.props}
  @override
  List<Object?> get props => [...super.props, wantedLocale];
}
