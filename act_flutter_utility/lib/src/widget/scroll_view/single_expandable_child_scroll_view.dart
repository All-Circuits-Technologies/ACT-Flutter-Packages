// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';

/// This widget allows to have expanded child in a single child scroll view: the [child] widget
/// expanded to the max and if the view is smaller than the child, the child will be scrollable.
///
/// Please note, we use [IntrinsicHeight] here which is expensive. Therefore, only use this widget
/// if you can't do something else
class SingleExpandableChildScrollView extends StatelessWidget {
  /// This is scroll controller
  final ScrollController? controller;

  /// This is the scroll physics to set on the scroll view
  final ScrollPhysics? physics;

  /// This is the scroll direction of the scroll view
  final Axis scrollDirection;

  /// The expandable child
  final Widget child;

  /// Class constructor
  const SingleExpandableChildScrollView({
    super.key,
    this.controller,
    this.physics,
    this.scrollDirection = Axis.vertical,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: scrollDirection,
          controller: controller,
          physics: physics,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        ),
      );
}
