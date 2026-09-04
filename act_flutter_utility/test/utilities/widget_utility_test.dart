// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("WidgetUtility.formatInputLabelText", () {
    test("labels a required input which has no text with the mark alone", () {
      expect(WidgetUtility.formatInputLabelText(labelText: null, inputRequired: true), "*");
    });

    test("labels an optional input which has no text with the mark alone", () {
      expect(WidgetUtility.formatInputLabelText(labelText: null, inputRequired: false), "*");
    });

    test("marks the label of a required input", () {
      expect(WidgetUtility.formatInputLabelText(labelText: "Name", inputRequired: true), "Name *");
    });

    test("leaves the label of an optional input alone", () {
      expect(WidgetUtility.formatInputLabelText(labelText: "Name", inputRequired: false), "Name");
    });

    test("marks a label which ends with a space only once", () {
      expect(
        WidgetUtility.formatInputLabelText(labelText: "Name  ", inputRequired: true),
        "Name *",
      );
    });

    test("leaves a label which is already marked alone", () {
      expect(
        WidgetUtility.formatInputLabelText(labelText: "Name *", inputRequired: true),
        "Name *",
      );
    });

    test("marks nothing when the label is empty", () {
      expect(WidgetUtility.formatInputLabelText(labelText: "", inputRequired: true), "");
    });
  });

  group("WidgetUtility.getSizeWithPercent", () {
    test("takes the share of the size the percent asks for", () {
      expect(WidgetUtility.getSizeWithPercent(200, 25), 50);
    });

    test("gives the whole size back for a hundred percent", () {
      expect(WidgetUtility.getSizeWithPercent(200, 100), 200);
    });
  });

  group("WidgetUtility.getSizeWithFactor", () {
    test("multiplies the size by the factor", () {
      expect(WidgetUtility.getSizeWithFactor(200, 1.5), 300);
    });
  });

  group("WidgetUtility.getSizeElem", () {
    test("takes the share of the size the percent asks for", () {
      expect(WidgetUtility.getSizeElem(200, percentToApplyOnSize: 50), 100);
    });

    test("gives the whole size back when no percent is asked for", () {
      expect(WidgetUtility.getSizeElem(200), 200);
    });

    test("raises a size which falls under the minimum", () {
      expect(WidgetUtility.getSizeElem(200, percentToApplyOnSize: 10, minSizeElem: 50), 50);
    });

    test("lowers a size which passes the maximum", () {
      expect(WidgetUtility.getSizeElem(200, maxSizeElem: 150), 150);
    });

    test("leaves a size which is between the bounds alone", () {
      expect(WidgetUtility.getSizeElem(200, minSizeElem: 50, maxSizeElem: 300), 200);
    });

    test("refuses a minimum which is above the maximum", () {
      expect(
        () => WidgetUtility.getSizeElem(200, minSizeElem: 300, maxSizeElem: 50),
        throwsAssertionError,
      );
    });
  });

  group("WidgetUtility.getHeightElemFromParent", () {
    /// Builds the widget of a page of [height] logical pixels, and reads the height it computes.
    Future<double> heightIn(
      WidgetTester tester,
      double height,
      double Function(BuildContext context) read,
    ) async {
      late double result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(400, height)),
          child: Builder(
            builder: (context) {
              result = read(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      return result;
    }

    testWidgets("takes the share of the height of the page the percent asks for", (tester) async {
      final height = await heightIn(
        tester,
        800,
        (context) => WidgetUtility.getHeightElemFromParent(context, percentToApplyOnParent: 50),
      );

      expect(height, 400);
    });

    testWidgets("never asks for more than the height of the page", (tester) async {
      final height = await heightIn(
        tester,
        800,
        (context) => WidgetUtility.getHeightElemFromParent(context, minHeight: 1000),
      );

      expect(height, 800);
    });

    testWidgets("lowers a height which passes the maximum", (tester) async {
      final height = await heightIn(
        tester,
        800,
        (context) => WidgetUtility.getHeightElemFromParent(context, maxHeight: 300),
      );

      expect(height, 300);
    });
  });

  group("WidgetUtility.getWidthElemFromParent", () {
    /// Builds the widget of a page of [width] logical pixels, and reads the width it computes.
    Future<double> widthIn(
      WidgetTester tester,
      double width,
      double Function(BuildContext context) read,
    ) async {
      late double result;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(width, 800)),
          child: Builder(
            builder: (context) {
              result = read(context);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      return result;
    }

    testWidgets("takes the share of the width of the page the percent asks for", (tester) async {
      final width = await widthIn(
        tester,
        400,
        (context) => WidgetUtility.getWidthElemFromParent(context, percentToApplyOnParent: 25),
      );

      expect(width, 100);
    });

    testWidgets("never asks for more than the width of the page", (tester) async {
      final width = await widthIn(
        tester,
        400,
        (context) => WidgetUtility.getWidthElemFromParent(context, maxWidth: 1000),
      );

      expect(width, 400);
    });
  });

  group("WidgetUtility.getIconDataWidget", () {
    test("draws the icon at the size and in the color it is given", () {
      final widget =
          WidgetUtility.getIconDataWidget(icon: Icons.done, size: 12, color: Colors.red) as Icon;

      expect(widget.icon, Icons.done);
      expect(widget.size, 12);
      expect(widget.color, Colors.red);
    });
  });

  group("WidgetUtility.getElementsIconWidget", () {
    test("keeps the whole picture inside the size it is given", () {
      final widget =
          WidgetUtility.getElementsIconWidget(iconAsset: "assets/an_icon.png", size: 12) as Image;

      expect(widget.height, 12);
      expect(widget.fit, BoxFit.contain);
    });
  });

  group("WidgetUtility.isGlobalPositionOverWidget", () {
    testWidgets("says a position inside the widget is over it", (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(key: key, width: 100, height: 50),
        ),
      );

      expect(WidgetUtility.isGlobalPositionOverWidget(const Offset(50, 25), key), isTrue);
    });

    testWidgets("says a position outside the widget is not over it", (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Align(
          alignment: Alignment.topLeft,
          child: SizedBox(key: key, width: 100, height: 50),
        ),
      );

      expect(WidgetUtility.isGlobalPositionOverWidget(const Offset(150, 25), key), isFalse);
    });
  });

  group("WidgetUtility.addSingleChildScrollView", () {
    test("wraps the widget when the caller asks for a scroll", () {
      const child = SizedBox.shrink();

      final widget = WidgetUtility.addSingleChildScrollView(child: child, addCondition: true);

      expect((widget as SingleChildScrollView).child, child);
    });

    test("gives the widget back when the caller asks for no scroll", () {
      const child = SizedBox.shrink();

      final widget = WidgetUtility.addSingleChildScrollView(child: child, addCondition: false);

      expect(widget, child);
    });
  });
}
