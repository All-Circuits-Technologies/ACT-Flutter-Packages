// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/types/single_child_scroll_view_type.dart';
import 'package:act_flutter_utility/src/widget/scroll_view/single_expandable_child_scroll_view.dart';
import 'package:flutter/material.dart';

/// This widgets optionally embeds child within a simple or more complex single child scroll view
class OptionalSingleChildScrollView extends StatelessWidget {
  /// Wanted scroll view type
  final SingleChildScrollViewType scrollViewType;

  /// This is scroll controller
  final ScrollController? controller;

  /// This is the scroll physics to set on the scroll view
  final ScrollPhysics? physics;

  /// Widget to optionally embed within a scroll view
  final Widget child;

  /// Constructor
  const OptionalSingleChildScrollView({
    super.key,
    required this.scrollViewType,
    this.controller,
    this.physics,
    required this.child,
  });

  /// Build widget
  @override
  Widget build(BuildContext context) => switch (scrollViewType) {
        SingleChildScrollViewType.noScroll => child,
        SingleChildScrollViewType.scroll => SingleChildScrollView(
            controller: controller,
            physics: physics,
            child: child,
          ),
        SingleChildScrollViewType.expandedScroll => SingleExpandableChildScrollView(
            controller: controller,
            physics: physics,
            child: child,
          ),
      };
}
