// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/widget/tab_bars/abs_simple_tab_bar.dart';
import 'package:flutter/material.dart';

/// This mixin is used to define useful methods for the state of the [AbsSimpleTabBar] widget.
mixin MixinSimpleTabBarState<T extends AbsSimpleTabBar<T>> on State<T> {
  /// This is the current known index
  late int _currentKnownIndex;

  /// {@template act_flutter_utility.MixinSimpleTabBarState.rebuildViewIfIndexIsUpdated}
  /// If true, we rebuild the view if index is updated.
  /// {@endtemplate}
  @protected
  bool get rebuildViewIfIndexIsUpdated => false;

  /// Used to get the current know index value
  ///
  /// The value is only relevant if [widget] onTabIdxUpdated method has been given or if the
  /// [rebuildViewIfIndexIsUpdated] method returns true
  @protected
  int get currentKnownIndex => _currentKnownIndex;

  /// This is the current default tab controller
  TabController? _defaultTabController;

  /// Init the state
  @override
  void initState() {
    super.initState();
    _currentKnownIndex = widget.initialIndex;
  }

  /// {@template act_flutter_utility.MixinSimpleTabBarState.buildTabElements}
  /// This method has to be overridden with TabBar and TabBarView
  /// {@endtemplate}
  @protected
  Widget buildTabElements(BuildContext context);

  @override
  Widget build(BuildContext context) => DefaultTabController(
        initialIndex: widget.initialIndex,
        length: widget.tabBarConfigs.length,
        animationDuration: widget.animationDuration,
        child: Builder(
          builder: (context) {
            if ((widget.onTabIdxUpdated != null || rebuildViewIfIndexIsUpdated) &&
                _defaultTabController == null) {
              // We get the current [DefaultTabController] and adds a listener on it
              _defaultTabController = DefaultTabController.maybeOf(context);
              _defaultTabController!.addListener(_onControllerUpdated);
            }

            return buildTabElements(context);
          },
        ),
      );

  /// Called each time the [_defaultTabController] is modified, and update the [_currentKnownIndex]
  ///
  /// It also calls the [widget].onTabIdxUpdated method
  void _onControllerUpdated() {
    if (_defaultTabController == null || _defaultTabController!.index == _currentKnownIndex) {
      // Nothing to do
      return;
    }

    // If don't want to rebuild the view, we don't need to call setState
    if (rebuildViewIfIndexIsUpdated) {
      setState(_updateCurrentKnownIndex);
    } else {
      _updateCurrentKnownIndex();
    }
  }

  /// Updates the [_currentKnownIndex] with the current index of the [_defaultTabController]
  void _updateCurrentKnownIndex() {
    _currentKnownIndex = _defaultTabController!.index;
    widget.onTabIdxUpdated?.call(_defaultTabController!.index);
  }

  /// Called to dispose the state
  @override
  void dispose() {
    _defaultTabController?.removeListener(_onControllerUpdated);
    _defaultTabController = null;
    super.dispose();
  }
}
