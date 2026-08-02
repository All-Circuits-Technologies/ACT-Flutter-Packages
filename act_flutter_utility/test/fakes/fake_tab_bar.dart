// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';

/// The tab bar of a page, built the way an application builds one.
class FakeTabBar extends AbsSimpleTabBar<FakeTabBar> {
  /// {@macro act_flutter_utility.MixinSimpleTabBarState.rebuildViewIfIndexIsUpdated}
  final bool rebuildViewIfIndexIsUpdated;

  /// Class constructor
  const FakeTabBar({
    super.key,
    required super.tabBarConfigs,
    super.initialIndex,
    super.onTabIdxUpdated,
    super.animationDuration,
    this.rebuildViewIfIndexIsUpdated = false,
  });

  @override
  MixinSimpleTabBarState<FakeTabBar> createState() => _FakeTabBarState();
}

/// The state of the tab bar of a page.
class _FakeTabBarState extends State<FakeTabBar> with MixinSimpleTabBarState<FakeTabBar> {
  @override
  bool get rebuildViewIfIndexIsUpdated => widget.rebuildViewIfIndexIsUpdated;

  /// {@macro act_flutter_utility.MixinSimpleTabBarState.buildTabElements}
  @override
  Widget buildTabElements(BuildContext context) => Column(
    children: [
      TabBar(tabs: [for (final config in widget.tabBarConfigs) Tab(text: config.title)]),
      Text("tab $currentKnownIndex"),
      Expanded(
        child: TabBarView(children: [for (final config in widget.tabBarConfigs) config.child]),
      ),
    ],
  );
}
