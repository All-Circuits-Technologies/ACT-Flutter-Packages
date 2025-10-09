// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui' show Locale;

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// Emitted when the wanted locale is updated by the user
class WantedLocaleUpdatedByUserEvent extends BlocEventForMixin {
  /// The wanted locale by user
  final Locale? wantedLocale;

  /// Class constructor
  const WantedLocaleUpdatedByUserEvent({
    required this.wantedLocale,
  });

  /// {@macro act_flutter_utility.BlocEventForMixin.props}
  @override
  List<Object?> get props => [...super.props, wantedLocale];
}
