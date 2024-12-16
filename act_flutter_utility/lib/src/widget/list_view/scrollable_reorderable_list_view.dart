// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:flutter/material.dart';

/// This is a custom [ReorderableListView] to manage scroll when the listview is embedded in a
/// scrolling page.
///
/// If [scrollable] is equal to true, this is a classical [ReorderableListView].
/// If [scrollable] is equal to false, the [ReorderableListView] isn't scrollable by itself. But, by
/// default, when the users drags elements the all view doesn't scroll. To do that this widget
/// listen the drag position and force scrolling thanks to the given [parentScrollController].
/// Therefore, the given controller has to be the scroll controller of the page.
///
/// The scrolling code is copied from
/// https://geekyants.com/blog/creating-nested-reorderable-lists-with-custom-scrolling-in-flutter
class ScrollableReorderableListView extends StatelessWidget {
  /// This is the step to automatically scroll with
  static const _scrollStep = 10.0;

  /// This is the threshold to detect the need of scrolling
  static const _scrollThreshold = 100.0;

  /// This is the duration to wait between each automatic scroll
  static const _scrollDuration = Duration(milliseconds: 20);

  /// This is the parent scroll controller
  ///
  /// If [scrollable] is equal to false and if you want to scroll the page when dragging elements,
  /// this has to be the page scroll controller.
  final ScrollController? parentScrollController;

  /// True if the [ReorderableListView] is scrollable by itself.
  /// False if we want to expand the list view items in a scrollable page.
  final bool scrollable;

  /// This is called when the user releases the dragging of an items. It contains the old and new
  /// index of the item in the children list
  ///
  /// This is an example of how to manage the reorder for the list:
  ///
  /// ```dart
  /// final child = children.removeAt(oldIndex);
  /// var tmpNewIdx = newIndex;
  /// if (oldIndex < newIndex) {
  ///   tmpNewIdx = newIndex - 1;
  /// }
  /// children.insert(tmpNewIdx, child);
  /// ```
  final ReorderCallback onReorder;

  /// True to use the default drag handle (it's not the same behaviour on windows and phone).
  /// False to disable the dragging
  final bool buildDefaultDragHandles;

  /// The children to display
  ///
  /// Be sure that each child has an unique key: this is needed to allow dragging of elements.
  final List<Widget> children;

  /// Class constructor
  const ScrollableReorderableListView({
    super.key,
    required this.children,
    required this.onReorder,
    this.parentScrollController,
    this.scrollable = true,
    this.buildDefaultDragHandles = true,
  });

  @override
  Widget build(BuildContext context) => _wrapListener(
        context: context,
        child: ReorderableListView(
          shrinkWrap: !scrollable,
          physics: scrollable ? null : const ClampingScrollPhysics(),
          onReorder: onReorder,
          buildDefaultDragHandles: buildDefaultDragHandles,
          children: children,
        ),
      );

  /// Start the auto scroll process
  Timer? _startAutoScroll(
    BuildContext context,
    ScrollController scrollController,
    Timer? timer,
    double dy,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (dy < _scrollThreshold) {
      return _startScrolling(scrollController, timer, -_scrollStep);
    }

    if (dy > screenHeight - _scrollThreshold) {
      return _startScrolling(scrollController, timer, _scrollStep);
    }

    return _stopScrolling(timer);
  }

  /// Start scrolling and move the scroller periodically
  Timer? _startScrolling(
    ScrollController scrollController,
    Timer? timer,
    double step,
  ) {
    _stopScrolling(timer);

    return Timer.periodic(_scrollDuration, (timer) {
      final newOffset = (scrollController.offset + step).clamp(
        0.0,
        scrollController.position.maxScrollExtent,
      );
      scrollController.jumpTo(newOffset);
    });
  }

  /// Stop the timer which manage the auto scrolling
  Timer? _stopScrolling(Timer? timer) {
    timer?.cancel();
    return null;
  }

  /// If the element isn't scrollable by itself, the method adds a listener to the child, in order
  /// to move the scroll with the user dragging.
  Widget _wrapListener({
    required BuildContext context,
    required Widget child,
  }) {
    if (scrollable) {
      return child;
    }

    if (parentScrollController == null) {
      return child;
    }

    Timer? timer;
    return Listener(
      onPointerMove: (event) {
        timer = _startAutoScroll(context, parentScrollController!, timer, event.position.dy);
      },
      onPointerUp: (event) {
        timer = _stopScrolling(timer);
      },
      onPointerCancel: (event) {
        timer = _stopScrolling(timer);
      },
      child: child,
    );
  }
}
