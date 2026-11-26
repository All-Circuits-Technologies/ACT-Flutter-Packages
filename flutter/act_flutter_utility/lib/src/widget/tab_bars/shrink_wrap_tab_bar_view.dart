// SPDX-FileCopyrightText: 2026 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';

/// A [TabBarView] as high as its current tab, for the tabs laid out where the height is not
/// bounded, such as in a scrollable page.
///
/// It keeps the gestures and the animation of [TabBarView], driven by the [TabController] of the
/// closest [DefaultTabController]. While the view moves from a tab to the next, its height goes
/// from the height of the one to the height of the other.
///
/// It needs a [DefaultTabController] above it.
///
/// A tab is laid out with an unbounded height: it must have a finite height of its own, without
/// widgets which expand to fill their parent, such as [Expanded] or a [ListView] which does not
/// shrink wrap. The view takes the height of a tab the frame after the tab is laid out: it is empty
/// on the first frame.
class ShrinkWrapTabBarView extends StatefulWidget {
  /// One widget per tab, in the order of the tabs of the [TabBar]
  final List<Widget> children;

  /// Class constructor
  const ShrinkWrapTabBarView({super.key, required this.children});

  /// Create the state of the view
  @override
  State<ShrinkWrapTabBarView> createState() => _ShrinkWrapTabBarViewState();
}

/// The state of [ShrinkWrapTabBarView], which keeps the height measured of each tab
class _ShrinkWrapTabBarViewState extends State<ShrinkWrapTabBarView> {
  /// The height of each tab, by index, once the tab has been laid out
  final Map<int, double> _heights = {};

  /// Called when the tab at [index] is laid out with the given [height]
  ///
  /// The layout is not the time to rebuild: the view is rebuilt once the frame is done.
  void _onTabHeight(int index, double height) {
    if (_heights[index] == height) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _heights[index] = height);
      }
    });
  }

  /// The height of the view when the animation of [controller] is at [position]
  ///
  /// Between two tabs, the height goes from the one to the other.
  double _heightAt(TabController controller, double position) {
    // A tap moves from the previous tab to the new one, even a far one; a drag between neighbours
    final fromIndex = controller.indexIsChanging ? controller.previousIndex : position.floor();
    final toIndex = controller.indexIsChanging ? controller.index : position.ceil();

    // Where the view is between the tab at fromIndex (0) and the tab at toIndex (1)
    final progress = (fromIndex == toIndex) ? 0.0 : (position - fromIndex) / (toIndex - fromIndex);

    // A tab not measured yet takes the height of the other one
    final fromHeight = _heights[fromIndex] ?? _heights[toIndex] ?? 0;
    final toHeight = _heights[toIndex] ?? fromHeight;

    return fromHeight * (1 - progress) + toHeight * progress;
  }

  /// Build the view
  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    final animation = controller.animation!;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) =>
          SizedBox(height: _heightAt(controller, animation.value), child: child),
      child: TabBarView(
        children: [
          for (final (index, tab) in widget.children.indexed)
            // The tab takes the height it needs, whatever the height of the view
            OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: _HeightProbe(onHeight: (height) => _onTabHeight(index, height), child: tab),
            ),
        ],
      ),
    );
  }
}

/// Reports the height of its [child] each time it is laid out
class _HeightProbe extends SingleChildRenderObjectWidget {
  /// Called with the height of the child after each layout
  final ValueChanged<double> onHeight;

  /// Class constructor
  const _HeightProbe({required this.onHeight, required super.child});

  /// Create the render object which reports the height
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderHeightProbe(onHeight: onHeight);

  /// Give the render object the callback of the last build
  @override
  void updateRenderObject(BuildContext context, _RenderHeightProbe renderObject) =>
      renderObject.onHeight = onHeight;
}

/// The render object of [_HeightProbe]
class _RenderHeightProbe extends RenderProxyBox {
  /// Called with the height of the child after each layout
  ValueChanged<double> onHeight;

  /// Class constructor
  _RenderHeightProbe({required this.onHeight});

  /// Lay out the child, then report its height
  @override
  void performLayout() {
    super.performLayout();
    onHeight(size.height);
  }
}
