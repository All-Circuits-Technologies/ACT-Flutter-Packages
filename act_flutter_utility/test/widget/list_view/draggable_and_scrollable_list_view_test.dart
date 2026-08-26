// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Shows a page holding the list under test.
  Future<void> aPage(
    WidgetTester tester, {
    ReorderCallback? dragReorder,
    bool scrollable = true,
    bool isLoading = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DraggableAndScrollableListView(
          dragReorder: dragReorder,
          scrollable: scrollable,
          isLoading: isLoading,
          children: const [
            Text("first", key: ValueKey("first")),
            Text("second", key: ValueKey("second")),
          ],
        ),
      ),
    ),
  );

  group("DraggableAndScrollableListView", () {
    testWidgets("shows the children it was given", (tester) async {
      await aPage(tester);

      expect(find.text("first"), findsOneWidget);
      expect(find.text("second"), findsOneWidget);
    });

    testWidgets("shows a plain list when the children cannot be moved", (tester) async {
      await aPage(tester);

      expect(find.byType(ReorderableListView), findsNothing);
    });

    testWidgets("shows a list the user can reorder when the children can be moved", (tester) async {
      await aPage(tester, dragReorder: (oldIndex, newIndex) {});

      expect(find.byType(ScrollableReorderableListView), findsOneWidget);
    });

    testWidgets("lets the parent scroll a plain list which is not scrollable", (tester) async {
      await aPage(tester, scrollable: false);

      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.shrinkWrap, isTrue);
      expect(list.physics, isA<ClampingScrollPhysics>());
    });

    testWidgets("holds the drag handles back while the page is loading", (tester) async {
      await aPage(tester, dragReorder: (oldIndex, newIndex) {}, isLoading: true);

      final list = tester.widget<ReorderableListView>(find.byType(ReorderableListView));
      expect(list.buildDefaultDragHandles, isFalse);
    });

    testWidgets("offers the drag handles once the page is loaded", (tester) async {
      await aPage(tester, dragReorder: (oldIndex, newIndex) {});

      final list = tester.widget<ReorderableListView>(find.byType(ReorderableListView));
      expect(list.buildDefaultDragHandles, isTrue);
    });
  });
}
