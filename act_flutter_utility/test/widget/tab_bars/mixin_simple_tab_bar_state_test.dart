// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_tab_bar.dart';

/// The tabs of the page of the tests.
const _tabs = [
  ActTabBarConfig(title: "first", child: Text("the first page")),
  ActTabBarConfig(title: "second", child: Text("the second page")),
];

void main() {
  /// Shows a page holding the tab bar under test.
  Future<void> aPage(
    WidgetTester tester, {
    int initialIndex = 0,
    ValueChanged<int>? onTabIdxUpdated,
    bool rebuildViewIfIndexIsUpdated = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        // The tests read which tab is shown, not how it lights up under the finger.
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: FakeTabBar(
            tabBarConfigs: _tabs,
            initialIndex: initialIndex,
            onTabIdxUpdated: onTabIdxUpdated,
            rebuildViewIfIndexIsUpdated: rebuildViewIfIndexIsUpdated,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group("MixinSimpleTabBarState", () {
    testWidgets("shows a tab per configuration it was given", (tester) async {
      await aPage(tester);

      expect(find.text("first"), findsOneWidget);
      expect(find.text("second"), findsOneWidget);
    });

    testWidgets("shows the page of the tab the user starts on", (tester) async {
      await aPage(tester, initialIndex: 1);

      expect(find.text("the second page"), findsOneWidget);
    });

    testWidgets("shows the page of the tab the user moved to", (tester) async {
      await aPage(tester);

      await tester.tap(find.text("second"));
      await tester.pumpAndSettle();

      expect(find.text("the second page"), findsOneWidget);
    });

    testWidgets("tells the page which tab the user moved to", (tester) async {
      final indexes = <int>[];
      await aPage(tester, onTabIdxUpdated: indexes.add);

      await tester.tap(find.text("second"));
      await tester.pumpAndSettle();

      expect(indexes, [1]);
    });

    testWidgets("tells the page nothing while the user stays on the same tab", (tester) async {
      final indexes = <int>[];
      await aPage(tester, onTabIdxUpdated: indexes.add);

      await tester.tap(find.text("first"));
      await tester.pumpAndSettle();

      expect(indexes, isEmpty);
    });

    testWidgets("builds the tab bar again when it was told to", (tester) async {
      await aPage(tester, rebuildViewIfIndexIsUpdated: true);

      await tester.tap(find.text("second"));
      await tester.pumpAndSettle();

      expect(find.text("tab 1"), findsOneWidget);
    });

    testWidgets("leaves the tab bar as it is when it was not told to build it again", (
      tester,
    ) async {
      await aPage(tester);

      await tester.tap(find.text("second"));
      await tester.pumpAndSettle();

      expect(find.text("tab 0"), findsOneWidget);
    });

    testWidgets("stops following the tabs once the page is gone", (tester) async {
      final indexes = <int>[];
      await aPage(tester, onTabIdxUpdated: indexes.add);

      await tester.pumpWidget(const MaterialApp(home: Text("another page")));
      await tester.pumpAndSettle();

      expect(indexes, isEmpty);
    });
  });
}
