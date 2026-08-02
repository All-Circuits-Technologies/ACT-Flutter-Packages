// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The time a snack bar stays on the page when the user does not have to acknowledge it.
const _snackBarDuration = Duration(milliseconds: 3500);

void main() {
  final theme = ThemeData(colorScheme: const ColorScheme.light(error: Colors.orange));

  group("ActSnackBar", () {
    test("shows the text it was given", () {
      final snackBar = ActSnackBar(theme: theme, text: "saved");

      expect((snackBar.content as Text).data, "saved");
    });

    test("shows the text of the error when it is on error", () {
      final snackBar = ActSnackBar(
        theme: theme,
        text: "saved",
        errorText: "not saved",
        isOnError: true,
      );

      expect((snackBar.content as Text).data, "not saved");
    });

    test("shows the plain text when it is not on error", () {
      final snackBar = ActSnackBar(theme: theme, text: "saved", errorText: "not saved");

      expect((snackBar.content as Text).data, "saved");
    });

    test("shows the plain text when the error has none of its own", () {
      final snackBar = ActSnackBar(theme: theme, text: "saved", isOnError: true);

      expect((snackBar.content as Text).data, "saved");
    });

    test("paints the background with the error color when it is on error", () {
      final snackBar = ActSnackBar(theme: theme, text: "saved", isOnError: true);

      expect(snackBar.backgroundColor, theme.colorScheme.error);
    });

    test("leaves the background to the theme when it is not on error", () {
      final snackBar = ActSnackBar(theme: theme, text: "saved");

      expect(snackBar.backgroundColor, isNull);
    });

    test("goes away by itself when the user does not have to acknowledge it", () {
      final snackBar = ActSnackBar(theme: theme, text: "saved");

      expect(snackBar.duration, _snackBarDuration);
      expect(snackBar.showCloseIcon, isFalse);
    });

    test("waits for the user when it has to be acknowledged", () {
      final snackBar = ActSnackBar(theme: theme, text: "saved", forceAckByUser: true);

      expect(snackBar.duration, greaterThan(const Duration(days: 300)));
      expect(snackBar.showCloseIcon, isTrue);
    });
  });

  group("ActSnackBar.showActSnackBar", () {
    /// Shows a page whose only widget shows a snack bar saying "saved" when it is tapped.
    ///
    /// The reason the snack bar was closed for lands in the answer once it is gone.
    Future<Future<SnackBarClosedReason>> aPage(
      WidgetTester tester, {
      VoidCallback? extraAction,
    }) async {
      late Future<SnackBarClosedReason> closed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => closed = ActSnackBar.showActSnackBar(
                  context: context,
                  text: "saved",
                  extraAction: extraAction,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      return closed;
    }

    testWidgets("shows the snack bar above the page", (tester) async {
      await aPage(tester);

      expect(find.text("saved"), findsOneWidget);
    });

    testWidgets("says why the snack bar was closed", (tester) async {
      final closed = await aPage(tester);

      await tester.pump(_snackBarDuration);
      await tester.pumpAndSettle();

      expect(await closed, SnackBarClosedReason.timeout);
    });

    testWidgets("runs the extra action once the snack bar is gone", (tester) async {
      var actionRan = false;
      final closed = await aPage(tester, extraAction: () => actionRan = true);

      expect(actionRan, isFalse);
      await tester.pump(_snackBarDuration);
      await tester.pumpAndSettle();
      await closed;

      expect(actionRan, isTrue);
    });
  });
}
