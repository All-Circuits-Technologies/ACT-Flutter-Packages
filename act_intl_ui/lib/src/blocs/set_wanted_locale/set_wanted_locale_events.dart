// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' show Locale;

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// Emitted when user updates the wanted locale
class NewLocaleWantedByUserEvent extends BlocEventForMixin {
  /// The wanted locale by user
  final Locale? wantedLocale;

  /// Class constructor
  const NewLocaleWantedByUserEvent({
    required this.wantedLocale,
  });

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props, wantedLocale];
}

/// Emitted when the current locale has been updated
class CurrentLocaleUpdatedEvent extends BlocEventForMixin {
  /// The current system local
  final Locale currentLocale;

  /// Class constructor
  const CurrentLocaleUpdatedEvent({
    required this.currentLocale,
  });

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props, currentLocale];
}
