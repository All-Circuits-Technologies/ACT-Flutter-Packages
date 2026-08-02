// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Shows a page whose content is wrapped the way [scrollViewType] asks for.
  Future<void> aPage(
    WidgetTester tester,
    SingleChildScrollViewType scrollViewType, {
    ScrollController? controller,
    ScrollPhysics? physics,
    Axis scrollDirection = Axis.vertical,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: OptionalSingleChildScrollView(
          scrollViewType: scrollViewType,
          controller: controller,
          physics: physics,
          scrollDirection: scrollDirection,
          child: const Text("the content"),
        ),
      ),
    ),
  );

  group("OptionalSingleChildScrollView", () {
    testWidgets("shows the content it was given", (tester) async {
      await aPage(tester, SingleChildScrollViewType.noScroll);

      expect(find.text("the content"), findsOneWidget);
    });

    testWidgets("leaves the content alone when the page does not scroll", (tester) async {
      await aPage(tester, SingleChildScrollViewType.noScroll);

      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets("wraps the content in a scroll view when the page scrolls", (tester) async {
      await aPage(tester, SingleChildScrollViewType.scroll);

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(SingleExpandableChildScrollView), findsNothing);
    });

    testWidgets("wraps a content which expands in a scroll view of its own", (tester) async {
      await aPage(tester, SingleChildScrollViewType.expandedScroll);

      expect(find.byType(SingleExpandableChildScrollView), findsOneWidget);
    });

    testWidgets("hands the scroll view what it was given to scroll with", (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await aPage(
        tester,
        SingleChildScrollViewType.scroll,
        controller: controller,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
      );

      final view = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView));
      expect(view.controller, controller);
      expect(view.physics, isA<BouncingScrollPhysics>());
      expect(view.scrollDirection, Axis.horizontal);
    });
  });
}
