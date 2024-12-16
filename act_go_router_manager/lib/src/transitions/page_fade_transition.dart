// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Class for Fade transition page in GoRouter navigation
class PageFadeTransition extends CustomTransitionPage<void> {
  PageFadeTransition({
    super.key,
    required super.child,
  }) : super(
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation), child: child),
        );
}
