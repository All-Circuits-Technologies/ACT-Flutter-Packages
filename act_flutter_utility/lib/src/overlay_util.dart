// Copyright (c) 2020. BMS Circuits

import 'package:flutter/cupertino.dart';

/// Defines a factory to build the widget which will overlay the current view
///
/// The [hide] callback is useful for the current overlay widget in order to
/// close the current opened overlay
typedef Widget BuildWidgetToOverlay(BuildContext context, VoidCallback hide);

/// This class is helpful to display an overlay above the current page view
class OverlayUtil {
  /// This methods allows to display a widget above the current view
  ///
  /// [widgetFactory] allows to give a factory for creating an overlay widget
  static void show(
    BuildContext context,
    BuildWidgetToOverlay widgetFactory,
  ) {
    var overlay = _OverlayController(widgetFactory);
    overlay.show(context);
  }
}

/// This class manages the creation, displaying and closing of the overlay
class _OverlayController {
  OverlayEntry entry;

  /// Class constructor
  _OverlayController(BuildWidgetToOverlay widgetFactory) {
    entry = OverlayEntry(builder: (BuildContext context) {
      return _OverlayContainer(
        hideCallback: _onHideAsked,
        toOverlay: widgetFactory,
      );
    });
  }

  /// Call to show the overlay
  void show(BuildContext context) {
    Overlay.of(context).insert(entry);
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

  /// Class constructor
  ///
  /// [hideCallback] is called after animation when the widget has to be removed
  /// from overlay entries
  _OverlayContainer({
    Key key,
    this.toOverlay,
    this.hideCallback,
  }) : super(key: key);

  @override
  State createState() => _OverlayContainerState();
}

/// State of the overlay container
class _OverlayContainerState extends State<_OverlayContainer>
    with TickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _animation;
  bool first;

  @override
  void initState() {
    first = true;

    // Manage the fading
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);

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
      _controller.forward();
    }

    return FadeTransition(
      opacity: _animation,
      child: widget.toOverlay(context, () {
        // Only call the hide callback at the end of animation
        _controller.reverse().whenCompleteOrCancel(widget.hideCallback);
      }),
    );
  }
}
