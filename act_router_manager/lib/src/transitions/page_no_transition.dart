// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:go_router/go_router.dart';

/// Class for default transition page in GoRouter navigation
class PageNoTransition extends NoTransitionPage<void> {
  /// Class constructor
  const PageNoTransition({
    super.key,
    super.name,
    super.arguments,
    required super.child,
  }) : super();
}
