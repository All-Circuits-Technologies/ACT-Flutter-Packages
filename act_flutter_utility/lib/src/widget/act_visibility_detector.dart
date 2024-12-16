// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Widget used to detect show/hidden widget events.
///
/// The goal of this widget is to detect those visibility events:
/// - visible back after having been hidden
///
/// The goal of this widget is to detect those hidden events:
/// - hidden because another view is pushed over this widget
///   (thanks to VisibilityDetector, a bit slow due to a 500-ms debouncer inside VisibilityDetector)
/// - hidden because app is put inactive or paused
///   (thanks to LifeCycleManager, fast)
/// - hidden because of a scroll event
///   (thanks to VisibilityDetector, a bit slow due to a 500-ms debouncer inside VisibilityDetector)
///
/// But it voluntary does not detect hidden events due to widget being destroyed
/// which is, in ACT spirit, the job of the caller dispose override.
///
/// At the end, it very looks like Google VisibilityDetector but with those key differences:
/// - it detects events linked to app being minimized/restored
/// - it does not fire events upon dispose, and much less debouncer-delay after it
/// - it does not report partially-visible widgets (considered visible)
class ActVisibilityDetector extends StatefulWidget {
  /// Callback fired when widget gets hidden or visible-back.
  final Function(bool) onVisibilityChanged;

  /// Inner widget
  final Widget child;

  /// HiddenDetector constructor
  const ActVisibilityDetector({
    super.key,
    required this.onVisibilityChanged,
    required this.child,
  });

  /// Create [_ActVisibilityDetectorState] linked to [ActVisibilityDetector] stateful widget
  @override
  State<ActVisibilityDetector> createState() => _ActVisibilityDetectorState();
}

/// [ActVisibilityDetector] state class
///
/// State class (hence StatefulWidget) is actually required for its dispose method,
/// in order to cancel our subscriptions. State has no impact on build(), hence it
/// never uses setState().
class _ActVisibilityDetectorState extends State<ActVisibilityDetector>
    with WidgetsBindingObserver {
  /// Last visibility state, used to unbounce callbacks
  bool? _visible;

  /// VisibilityDetector requires a key, which is this one
  final Key _visibilityDetectorKey = UniqueKey();

  /// Initialize all members
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  /// Build widget tree
  @override
  Widget build(BuildContext context) => VisibilityDetector(
        key: _visibilityDetectorKey,
        onVisibilityChanged: (VisibilityInfo info) {
          _setVisible(info.visibleFraction > 0);
        },
        child: widget.child,
      );

  /// From WidgetsBindingObserver mixin, catches minimized or restored app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setVisible(true);
        break;
      default:
        // App is either inactive, paused or detached
        _setVisible(false);
        break;
    }
  }

  /// Visibility value modifier
  void _setVisible(bool visible) {
    if (visible == _visible || !mounted) {
      // Nothing to do
      // Note: VisibilityDetector fire events after dispose.
      // We don't want this behavior, hence the !mounted test.
      return;
    }

    _visible = visible;
    widget.onVisibilityChanged(_visible!);
  }

  /// Free resources
  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }
}
