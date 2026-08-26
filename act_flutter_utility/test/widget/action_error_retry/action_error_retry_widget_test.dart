// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Shows [widget] in a page which gives it a theme and a text direction.
  Future<void> aPage(WidgetTester tester, Widget widget) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

  /// The heights of the fixed spaces the widget draws.
  List<double?> fixedHeightsOf(WidgetTester tester) =>
      tester.widgetList<SizedBox>(find.byType(SizedBox)).map((box) => box.height).toList();

  group("ActionErrorRetryWidget", () {
    testWidgets("shows the content and the buttons it was given", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: false),
          content: Text("something went wrong"),
          buttons: [Text("retry")],
        ),
      );

      expect(find.text("something went wrong"), findsOneWidget);
      expect(find.text("retry"), findsOneWidget);
    });

    testWidgets("shows the header it was given", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: false),
          headerIcon: Icons.warning_amber_rounded,
          headerTitle: "no network",
          content: Text("something went wrong"),
          buttons: [],
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.text("no network"), findsOneWidget);
    });

    testWidgets("shows no header when it was given none", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: false),
          content: Text("something went wrong"),
          buttons: [],
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets("colors the header with the color of the theme", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: false, headerContentColor: Colors.red),
          headerIcon: Icons.warning_amber_rounded,
          headerTitle: "no network",
          content: Text("something went wrong"),
          buttons: [],
        ),
      );

      expect(tester.widget<Icon>(find.byType(Icon)).color, Colors.red);
      expect(tester.widget<Text>(find.text("no network")).style?.color, Colors.red);
    });

    testWidgets("separates the buttons by the height of the theme", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: false, buttonsSeparator: 42),
          content: Text("something went wrong"),
          buttons: [Text("retry"), Text("go back")],
        ),
      );

      expect(fixedHeightsOf(tester), contains(42));
    });

    testWidgets("separates the buttons only from one another", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: false, buttonsSeparator: 42),
          content: Text("something went wrong"),
          buttons: [Text("retry")],
        ),
      );

      expect(fixedHeightsOf(tester), isNot(contains(42)));
    });

    testWidgets("spreads the widget over its parent when the theme asks for it", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: true),
          content: Text("something went wrong"),
          buttons: [Text("retry")],
        ),
      );

      expect(find.byType(Spacer), findsNWidgets(3));
    });

    testWidgets("stacks the widget from its top when the theme asks for it", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: false),
          content: Text("something went wrong"),
          buttons: [Text("retry")],
        ),
      );

      expect(find.byType(Spacer), findsNothing);
      expect(fixedHeightsOf(tester), containsAll(<double>[90, 15]));
    });

    testWidgets("uses the padding of the theme instead of a space of its own", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: true, topPadding: 7, bottomPadding: 8),
          content: Text("something went wrong"),
          buttons: [Text("retry")],
        ),
      );

      expect(find.byType(Spacer), findsOneWidget);
      expect(fixedHeightsOf(tester), containsAll(<double>[7, 8]));
    });

    testWidgets("pads the content the way the theme asks for", (tester) async {
      await aPage(
        tester,
        const ActionErrorRetryWidget(
          theme: ActionErrorRetryTheme(expandInParent: false, contentPadding: EdgeInsets.all(11)),
          content: Text("something went wrong"),
          buttons: [],
        ),
      );

      final padding = tester.widget<Padding>(
        find.ancestor(of: find.text("something went wrong"), matching: find.byType(Padding)).first,
      );
      expect(padding.padding, const EdgeInsets.all(11));
    });
  });

  group("ActionErrorRetryWidget.textContent", () {
    testWidgets("shows the text it was given, styled by the theme", (tester) async {
      await aPage(
        tester,
        ActionErrorRetryWidget.textContent(
          theme: const ActionErrorRetryTheme(
            expandInParent: false,
            contentTextStyle: TextStyle(fontSize: 33),
          ),
          text: "something went wrong",
          buttons: const [],
        ),
      );

      expect(tester.widget<Text>(find.text("something went wrong")).style?.fontSize, 33);
    });
  });

  group("ActionErrorRetryWidget.textContentWithHeader", () {
    testWidgets("shows an error icon when it was given none", (tester) async {
      await aPage(
        tester,
        ActionErrorRetryWidget.textContentWithHeader(
          theme: const ActionErrorRetryTheme(expandInParent: false),
          text: "something went wrong",
          headerTitle: "error",
          buttons: const [],
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets("shows the icon it was given", (tester) async {
      await aPage(
        tester,
        ActionErrorRetryWidget.textContentWithHeader(
          theme: const ActionErrorRetryTheme(expandInParent: false),
          text: "something went wrong",
          headerIcon: Icons.warning_amber_rounded,
          buttons: const [],
        ),
      );

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
