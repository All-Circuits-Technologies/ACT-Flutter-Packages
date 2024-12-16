// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/widget/list_view/scrollable_reorderable_list_view.dart';
import 'package:flutter/material.dart';

/// This displays a draggable list view.
///
/// If [dragReorder] is null, this displays a [ListView].
/// If [dragReorder] is not null, this displays a [ScrollableReorderableListView] (be sure that each
/// child has an unique key: this is needed by [ScrollableReorderableListView] to allow the
/// dragging of elements).
class DraggableAndScrollableListView extends StatelessWidget {
  /// This is the callback called when an element is dragged in the list.
  ///
  /// If null, a [ListView] is displayed.
  /// If not null, a [ScrollableReorderableListView] is displayed.
  final ReorderCallback? dragReorder;

  /// This is the parent scroll controller.
  ///
  /// This is useful when we use a [ScrollableReorderableListView] with [scrollable] options equals
  /// to false.
  final ScrollController? parentScrollController;

  /// True if the element is scrollable by itself.
  /// False if all the element items are expanded in the parent.
  final bool scrollable;

  /// True if the page is loading, and so if the items are draggable, or not.
  final bool isLoading;

  /// The children to display in the list view
  ///
  /// If [dragReorder] is not null, be sure that each child has an unique key: this is needed by
  /// [ScrollableReorderableListView] to allow the dragging of elements.
  final List<Widget> children;

  const DraggableAndScrollableListView({
    super.key,
    this.dragReorder,
    this.parentScrollController,
    this.scrollable = true,
    this.isLoading = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    if (dragReorder == null) {
      return ListView(
        shrinkWrap: !scrollable,
        physics: scrollable ? null : const ClampingScrollPhysics(),
        children: children,
      );
    }

    return ScrollableReorderableListView(
      parentScrollController: parentScrollController,
      scrollable: scrollable,
      onReorder: dragReorder!,
      buildDefaultDragHandles: !isLoading,
      children: children,
    );
  }
}
