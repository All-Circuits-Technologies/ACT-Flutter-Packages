// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The number of items the page shows, enough for the page to be taller than the screen.
const _itemCount = 40;

/// The height of one item of the list.
const _itemHeight = 50.0;

void main() {
  /// Shows a page holding the list under test.
  ///
  /// The list is embedded in a page the [controller] scrolls, which is what a list which is not
  /// scrollable by itself needs.
  Future<void> aPage(WidgetTester tester, {ScrollController? controller, bool scrollable = false}) {
    final list = ScrollableReorderableListView(
      parentScrollController: controller,
      scrollable: scrollable,
      onReorderItem: (oldIndex, newIndex) {},
      children: [
        for (var index = 0; index < _itemCount; index++)
          SizedBox(key: ValueKey(index), height: _itemHeight, child: Text("item $index")),
      ],
    );

    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: scrollable ? list : SingleChildScrollView(controller: controller, child: list),
        ),
      ),
    );
  }

  group("ScrollableReorderableListView", () {
    testWidgets("shows the children it was given", (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await aPage(tester, controller: controller);

      expect(find.text("item 0"), findsOneWidget);
    });

    testWidgets("lets the parent scroll the list when it does not scroll itself", (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await aPage(tester, controller: controller);

      final list = tester.widget<ReorderableListView>(find.byType(ReorderableListView));
      expect(list.shrinkWrap, isTrue);
      expect(list.physics, isA<ClampingScrollPhysics>());
    });

    testWidgets("scrolls the page while the user drags an item to its top", (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await aPage(tester, controller: controller);
      controller.jumpTo(400);

      final gesture = await tester.startGesture(const Offset(200, 400));
      await gesture.moveTo(const Offset(200, 50));
      await tester.pump(const Duration(milliseconds: 100));
      final offsetWhileDragging = controller.offset;
      await gesture.up();
      await tester.pumpAndSettle();

      expect(offsetWhileDragging, lessThan(400));
    });

    testWidgets("stops scrolling the page once the user drops the item", (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await aPage(tester, controller: controller);
      controller.jumpTo(400);

      final gesture = await tester.startGesture(const Offset(200, 400));
      await gesture.moveTo(const Offset(200, 50));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();
      final offsetAfterDrop = controller.offset;
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.offset, offsetAfterDrop);
    });

    testWidgets("leaves the page alone while the user drags an item in its middle", (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await aPage(tester, controller: controller);
      controller.jumpTo(400);

      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveTo(const Offset(200, 320));
      await tester.pump(const Duration(milliseconds: 100));
      final offsetWhileDragging = controller.offset;
      await gesture.up();
      await tester.pumpAndSettle();

      expect(offsetWhileDragging, 400);
    });

    testWidgets("scrolls no page when it was given no controller", (tester) async {
      await aPage(tester);
      final position = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      position.jumpTo(400);

      final gesture = await tester.startGesture(const Offset(200, 400));
      await gesture.moveTo(const Offset(200, 50));
      await tester.pump(const Duration(milliseconds: 100));
      final offsetWhileDragging = position.pixels;
      await gesture.up();
      await tester.pumpAndSettle();

      expect(offsetWhileDragging, 400);
    });

    testWidgets("scrolls by itself when it was told to", (tester) async {
      await aPage(tester, scrollable: true);

      final list = tester.widget<ReorderableListView>(find.byType(ReorderableListView));
      expect(list.shrinkWrap, isFalse);
      expect(list.physics, isNull);
    });
  });
}
