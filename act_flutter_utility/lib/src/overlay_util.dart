// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter/cupertino.dart';

/// Defines a factory to build the widget which will overlay the current view
///
/// The [hide] callback is useful for the current overlay widget in order to
/// close the current opened overlay
typedef BuildWidgetToOverlay = Widget Function(
  BuildContext context,
  VoidCallback hide,
);

/// This class is helpful to display an overlay above the current page view
class OverlayUtil {
  /// This methods allows to display a widget above the current view
  ///
  /// [widgetFactory] allows to give a factory for creating an overlay widget
  static void show(
    BuildContext context,
    BuildWidgetToOverlay widgetFactory,
  ) {
    final overlay = _OverlayController(
      widgetFactory,
      context,
    );
    overlay.show(context);
  }
}

/// This class manages the creation, displaying and closing of the overlay
class _OverlayController {
  late OverlayEntry entry;

  /// Class constructor
  ///
  /// [widgetContext] is necessary to call function with context inside Overlay
  _OverlayController(
    BuildWidgetToOverlay widgetFactory,
    BuildContext widgetContext,
  ) {
    entry = OverlayEntry(
      builder: (BuildContext context) => _OverlayContainer(
        hideCallback: _onHideAsked,
        toOverlay: widgetFactory,
        widgetContext: widgetContext,
      ),
    );
  }

  /// Call to show the overlay
  void show(BuildContext context) {
    final overlayState = Overlay.maybeOf(context);

    if (overlayState == null) {
      appLogger().w("Can't show overlay on the current build context owned "
          "by ${context.owner}");
      return;
    }

    final notNullOverlayState = overlayState;
    notNullOverlayState.insert(entry);
  }

  /// Call when hide has been asked
  void _onHideAsked() {
    entry.remove();
  }
}

/// This class contains the widget to display in overlay
class _OverlayContainer extends StatefulWidget {
  final BuildWidgetToOverlay toOverlay;
  final VoidCallback hideCallback;
  final BuildContext widgetContext;

  /// Class constructor
  ///
  /// [hideCallback] is called after animation when the widget has to be removed
  /// from overlay entries
  const _OverlayContainer({
    required this.toOverlay,
    required this.hideCallback,
    required this.widgetContext,
  });

  @override
  State createState() => _OverlayContainerState();
}

/// State of the overlay container
class _OverlayContainerState extends State<_OverlayContainer> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late bool first;

  @override
  void initState() {
    first = true;

    // Manage the fading
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_controller);

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (first) {
      unawaited(_controller.forward());
    }

    return FadeTransition(
      opacity: _animation,
      child: widget.toOverlay(
        widget.widgetContext,
        () {
          // Only call the hide callback at the end of animation
          _controller.reverse().whenCompleteOrCancel(widget.hideCallback);
        },
      ),
    );
  }
}
