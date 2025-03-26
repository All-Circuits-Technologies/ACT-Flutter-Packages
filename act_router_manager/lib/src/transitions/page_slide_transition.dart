// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Class for Slide transition page in GoRouter navigation
class PageSlideTransition extends CustomTransitionPage<void> {
  /// True if the slide is horizontal
  /// False if the slide is vertical
  final bool isAlignHorizontal;

  /// Class constructor
  PageSlideTransition({
    super.key,
    super.name,
    super.arguments,
    this.isAlignHorizontal = true,
    required super.child,
  }) : super(
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, animation, __, child) => SlideTransition(
            position: animation.drive(
              Tween(
                begin: isAlignHorizontal ? const Offset(1.5, 0) : const Offset(0, 1.5),
                end: Offset.zero,
              ).chain(
                CurveTween(curve: Curves.ease),
              ),
            ),
            child: child,
          ),
        );
}
