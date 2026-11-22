// SPDX-FileCopyrightText: 2026 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  /// Shows a scrollable page holding a tab per height of [heights], each tab as high as its height
  ///
  /// The first tab takes its height from [firstHeight] when it is given.
  Future<void> aPage(
    WidgetTester tester, {
    required List<double> heights,
    ValueNotifier<double>? firstHeight,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        // The tests read which tab is shown, not how it lights up under the finger.
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DefaultTabController(
              length: heights.length,
              child: Column(
                children: [
                  TabBar(tabs: [for (var idx = 0; idx < heights.length; ++idx) Tab(text: "$idx")]),
                  ShrinkWrapTabBarView(
                    children: [
                      for (final (idx, height) in heights.indexed)
                        ValueListenableBuilder(
                          valueListenable: (idx == 0 ? firstHeight : null) ?? ValueNotifier(height),
                          builder: (context, value, child) =>
                              SizedBox(height: value, child: Text("page $idx")),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The height of the view under test
  double heightOfTheView(WidgetTester tester) =>
      tester.getSize(find.byType(ShrinkWrapTabBarView)).height;

  group("ShrinkWrapTabBarView", () {
    testWidgets("is as high as the tab it shows", (tester) async {
      await aPage(tester, heights: [100, 300]);

      expect(find.text("page 0"), findsOneWidget);
      expect(heightOfTheView(tester), 100);
    });

    testWidgets("takes the height of the tab the user moved to", (tester) async {
      await aPage(tester, heights: [100, 300]);

      await tester.tap(find.text("1"));
      await tester.pumpAndSettle();

      expect(find.text("page 1"), findsOneWidget);
      expect(heightOfTheView(tester), 300);
    });

    testWidgets("moves to the next tab when the user drags it aside", (tester) async {
      await aPage(tester, heights: [100, 300]);

      await tester.fling(find.text("page 0"), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text("page 1"), findsOneWidget);
      expect(heightOfTheView(tester), 300);
    });

    testWidgets("follows the tab it shows when the tab changes its height", (tester) async {
      final firstHeight = ValueNotifier<double>(100);
      await aPage(tester, heights: [100, 300], firstHeight: firstHeight);

      firstHeight.value = 250;
      await tester.pumpAndSettle();

      expect(heightOfTheView(tester), 250);
    });

    testWidgets("is between the heights of the two tabs while it moves", (tester) async {
      await aPage(tester, heights: [100, 300]);

      await tester.tap(find.text("1"));
      await tester.pump();
      // The new tab is measured on the frame it shows up, and its height is used from the next one
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 50));

      expect(heightOfTheView(tester), allOf(greaterThan(100), lessThan(300)));
    });

    testWidgets("goes straight to a far tab, from the height of the tab it leaves", (tester) async {
      await aPage(tester, heights: [100, 50, 50, 400]);

      await tester.tap(find.text("3"));
      final heights = <double>[];
      for (var frame = 0; frame < 20; ++frame) {
        await tester.pump(const Duration(milliseconds: 20));
        heights.add(heightOfTheView(tester));
      }

      expect(heights, everyElement(inInclusiveRange(100, 400)));
      expect(heights.last, 400);
    });
  });
}
