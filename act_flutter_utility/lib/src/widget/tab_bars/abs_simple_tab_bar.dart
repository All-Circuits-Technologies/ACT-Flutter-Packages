// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/models/act_tab_bar_config.dart';
import 'package:act_flutter_utility/src/widget/tab_bars/mixin_simple_tab_bar_state.dart';
import 'package:flutter/material.dart';

/// This is a simple tab bar implementation to be used in your app.
abstract class AbsSimpleTabBar<T extends AbsSimpleTabBar<T>> extends StatefulWidget {
  /// This is the configs of the tab bar
  final List<ActTabBarConfig> tabBarConfigs;

  /// This is the initial index of the tab bar
  final int initialIndex;

  /// Called each time the hewo tab bar page has been changed
  ///
  /// The returned value is the index of the current page
  final ValueChanged<int>? onTabIdxUpdated;

  /// Controls the duration of the tab bar controller and TabBarView animations.
  ///
  /// If null, the default value is used
  final Duration? animationDuration;

  /// Class constructor
  const AbsSimpleTabBar({
    super.key,
    required this.tabBarConfigs,
    this.initialIndex = 0,
    this.onTabIdxUpdated,
    this.animationDuration,
  });

  /// Create the state linked to the [AbsSimpleTabBar]
  @override
  MixinSimpleTabBarState<T> createState();
}
