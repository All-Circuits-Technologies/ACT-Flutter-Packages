// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUp(() => VisibilityDetectorController.instance.updateInterval = Duration.zero);

  tearDown(
    () => VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 500),
  );

  /// Shows the widget under test, and records every visibility it reports.
  Future<List<bool>> aShownWidget(WidgetTester tester) async {
    final reported = <bool>[];

    await tester.pumpWidget(
      MaterialApp(
        home: ActVisibilityDetector(onVisibilityChanged: reported.add, child: const Text("shown")),
      ),
    );
    await tester.pumpAndSettle();

    return reported;
  }

  group("ActVisibilityDetector", () {
    testWidgets("shows the widget it wraps", (tester) async {
      await aShownWidget(tester);

      expect(find.text("shown"), findsOneWidget);
    });

    testWidgets("reports the widget as visible once it is shown", (tester) async {
      final reported = await aShownWidget(tester);

      expect(reported, [true]);
    });

    testWidgets("reports the widget as hidden when the application is put aside", (tester) async {
      final reported = await aShownWidget(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(reported, [true, false]);
    });

    testWidgets("reports the widget as visible when the application comes back", (tester) async {
      final reported = await aShownWidget(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(reported, [true, false, true]);
    });

    testWidgets("reports a visibility which does not change only once", (tester) async {
      final reported = await aShownWidget(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();

      expect(reported, [true, false]);
    });

    testWidgets("reports nothing once the widget is gone", (tester) async {
      final reported = await aShownWidget(tester);

      await tester.pumpWidget(const MaterialApp(home: Text("another page")));
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();

      expect(reported, [true]);
    });
  });
}
