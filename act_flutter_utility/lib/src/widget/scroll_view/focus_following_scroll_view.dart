// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:math' as math;

import 'package:act_flutter_utility/src/types/single_child_scroll_view_type.dart';
import 'package:act_flutter_utility/src/widget/scroll_view/optional_single_child_scroll_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A single child scroll view that keeps the currently focused descendant scrolled into view when
/// the focus moves through keyboard or directional traversal.
///
/// Flutter's default focus traversal already calls [Scrollable.ensureVisible], but on a wrap-around
/// (moving from the last focusable back to the first, or the other way around) it uses the
/// [ScrollPositionAlignmentPolicy.keepVisibleAtStart] / [ScrollPositionAlignmentPolicy.keepVisibleAtEnd]
/// policies, which only scroll in a single direction. The wrapped target then sits off-screen in the
/// opposite direction and the viewport does not move.
///
/// This widget overrides the traversal request-focus callback so that, whenever the newly focused
/// descendant is not already fully visible, it is revealed with
/// [ScrollPositionAlignmentPolicy.explicit] (which scrolls in both directions) using [alignment].
/// Descendants that are already visible are left untouched, so stepping between adjacent items stays
/// smooth.
class FocusFollowingScrollView extends StatelessWidget {
  /// Duration of the scroll animation played when a focused descendant is revealed.
  static const Duration _scrollDuration = Duration(milliseconds: 150);

  /// Curve of the scroll animation played when a focused descendant is revealed.
  static const Curve _scrollCurve = Curves.easeInOut;

  /// Tolerance, in logical pixels, used when checking whether a descendant is already fully visible.
  ///
  /// It absorbs sub-pixel rounding so an item flush against a viewport edge is not needlessly
  /// scrolled.
  static const double _visibilityTolerance = 1;

  /// Where a revealed descendant is aligned within the viewport, from 0.0 (leading edge) to 1.0
  /// (trailing edge). 0.5 centers it.
  final double alignment;

  /// Wanted scroll view type
  final SingleChildScrollViewType scrollViewType;

  /// The scroll controller of the underlying scroll view.
  final ScrollController? controller;

  /// The scroll physics of the underlying scroll view.
  final ScrollPhysics? physics;

  /// The scroll direction of the underlying scroll view.
  final Axis scrollDirection;

  /// The scrollable content. Its focusable descendants are the ones kept in view.
  final Widget child;

  /// Class constructor
  const FocusFollowingScrollView({
    super.key,
    required this.child,
    this.alignment = 0.5,
    this.scrollViewType = SingleChildScrollViewType.scroll,
    this.controller,
    this.physics,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) => _wrapWithTraversalIfNeeded(
    child: OptionalSingleChildScrollView(
      scrollViewType: scrollViewType,
      scrollDirection: scrollDirection,
      controller: controller,
      physics: physics,
      child: child,
    ),
  );

  /// Wraps the given [child] with a [FocusTraversalGroup] if the scroll view type allows scrolling.
  ///
  /// If the scroll view type is [SingleChildScrollViewType.noScroll], the child is returned as-is
  /// without being wrapped in a [FocusTraversalGroup].
  Widget _wrapWithTraversalIfNeeded({required Widget child}) {
    if (scrollViewType == SingleChildScrollViewType.noScroll) {
      // If there is no scroll, it doesn't make sense to add the traversal group.
      return child;
    }

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(requestFocusCallback: _requestFocus),
      child: child,
    );
  }

  /// Request the focus on [node] and, when it is not already fully visible, scroll it into view.
  ///
  /// This replaces the framework default, which refuses to scroll backwards on a traversal
  /// wrap-around, by revealing the node with an explicit alignment that scrolls in both directions.
  /// The incoming alignment hints are ignored on purpose so that both the normal and the
  /// wrap-around moves land the node at the same [alignment].
  void _requestFocus(
    FocusNode node, {
    ScrollPositionAlignmentPolicy? alignmentPolicy,
    double? alignment,
    Duration? duration,
    Curve? curve,
  }) {
    node.requestFocus();

    final nodeContext = node.context;
    if (nodeContext == null) {
      return;
    }

    if (_isFullyVisible(nodeContext)) {
      // Already visible: leave the offset untouched so stepping between adjacent items stays smooth.
      return;
    }

    // The default alignment policy is already [ScrollPositionAlignmentPolicy.explicit], which scrolls
    // in both directions and so reveals a wrapped-around target the framework default would skip.
    unawaited(
      Scrollable.ensureVisible(
        nodeContext,
        alignment: this.alignment,
        duration: _scrollDuration,
        curve: _scrollCurve,
      ),
    );
  }

  /// Whether the render object behind [context] is currently fully visible inside its enclosing
  /// viewport.
  ///
  /// Returns true when there is no enclosing scrollable, since there is then nothing to scroll.
  static bool _isFullyVisible(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) {
      return false;
    }

    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    final scrollable = Scrollable.maybeOf(context);
    if (viewport == null || scrollable == null) {
      return true;
    }

    // Offsets that would bring the object's leading and trailing edges onto the viewport edges. The
    // object is fully visible while the current offset sits between them.
    final leadingReveal = viewport.getOffsetToReveal(renderObject, 0).offset;
    final trailingReveal = viewport.getOffsetToReveal(renderObject, 1).offset;
    final minReveal = math.min(leadingReveal, trailingReveal);
    final maxReveal = math.max(leadingReveal, trailingReveal);

    final pixels = scrollable.position.pixels;
    return pixels >= minReveal - _visibilityTolerance && pixels <= maxReveal + _visibilityTolerance;
  }
}
