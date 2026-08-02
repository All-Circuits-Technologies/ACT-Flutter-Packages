// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The size of the page the content of the tests is shown in.
const _viewSize = 200.0;

/// The widget a test measures to know where the content ends.
const _endKey = ValueKey("end");

void main() {
  /// Shows a page of [_viewSize] logical pixels holding [child].
  Future<void> aPage(WidgetTester tester, Widget child, {Axis scrollDirection = Axis.vertical}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: _viewSize,
                height: _viewSize,
                child: SingleExpandableChildScrollView(
                  scrollDirection: scrollDirection,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );

  /// The extent the content of the page can be scrolled by.
  double scrollExtentOf(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position.maxScrollExtent;

  group("SingleExpandableChildScrollView", () {
    testWidgets("stretches a content which is smaller than the page", (tester) async {
      await aPage(
        tester,
        const Column(
          children: [
            Spacer(),
            SizedBox(key: _endKey, height: 20, width: 20),
          ],
        ),
      );

      expect(tester.getSize(find.byType(Column)).height, _viewSize);
    });

    testWidgets("leaves a content which is smaller than the page unscrollable", (tester) async {
      await aPage(
        tester,
        const Column(
          children: [
            Spacer(),
            SizedBox(key: _endKey, height: 20, width: 20),
          ],
        ),
      );

      expect(scrollExtentOf(tester), 0);
    });

    testWidgets("scrolls a content which is taller than the page", (tester) async {
      await aPage(tester, const SizedBox(key: _endKey, height: 400, width: 20));

      expect(scrollExtentOf(tester), 400 - _viewSize);
    });

    testWidgets("stretches a content which is narrower than the page", (tester) async {
      await aPage(
        tester,
        const Row(
          children: [
            Spacer(),
            SizedBox(key: _endKey, height: 20, width: 20),
          ],
        ),
        scrollDirection: Axis.horizontal,
      );

      expect(tester.getSize(find.byType(Row)).width, _viewSize);
    });

    testWidgets("scrolls a content which is wider than the page", (tester) async {
      await aPage(
        tester,
        const SizedBox(key: _endKey, height: 20, width: 400),
        scrollDirection: Axis.horizontal,
      );

      expect(scrollExtentOf(tester), 400 - _viewSize);
    });
  });
}
