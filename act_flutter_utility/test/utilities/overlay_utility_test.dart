// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The duration of the fading of the overlay, in and out.
const _fadeDuration = Duration(milliseconds: 250);

void main() {
  late FakeLogger logger;
  late FakeGlobalManager globalManager;

  setUp(() {
    logger = FakeLogger();
    globalManager = FakeGlobalManager.install(logger: logger);
  });

  tearDown(() => globalManager.reset());

  /// Builds a page whose only widget shows an overlay saying "over" when it is tapped.
  ///
  /// The page is wrapped in an [Overlay] unless [withOverlay] is false, which is what a page which
  /// asks for an overlay outside of a navigator looks like.
  Future<void> aPage(
    WidgetTester tester, {
    required void Function(VoidCallback hide) onOverlayBuilt,
    bool withOverlay = true,
  }) async {
    final page = Builder(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => OverlayUtility.show(context, (context, hide) {
          onOverlayBuilt(hide);

          return const Text("over", textDirection: TextDirection.ltr);
        }),
        child: const SizedBox(width: 100, height: 100),
      ),
    );

    await tester.pumpWidget(
      withOverlay
          ? MaterialApp(home: Scaffold(body: page))
          : Directionality(textDirection: TextDirection.ltr, child: page),
    );
  }

  group("OverlayUtility.show", () {
    testWidgets("shows the widget the factory built above the page", (tester) async {
      await aPage(tester, onOverlayBuilt: (hide) {});

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      expect(find.text("over"), findsOneWidget);
    });

    testWidgets("fades the widget in", (tester) async {
      await aPage(tester, onOverlayBuilt: (hide) {});

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      await tester.pump(_fadeDuration ~/ 2);

      final fade = tester.widget<FadeTransition>(
        find.ancestor(of: find.text("over"), matching: find.byType(FadeTransition)),
      );
      expect(fade.opacity.value, greaterThan(0));
      expect(fade.opacity.value, lessThan(1));
    });

    testWidgets("removes the widget once the caller hid it", (tester) async {
      late VoidCallback hide;
      await aPage(tester, onOverlayBuilt: (hideOverlay) => hide = hideOverlay);
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      hide();
      await tester.pumpAndSettle();

      expect(find.text("over"), findsNothing);
    });

    testWidgets("keeps the widget while it fades out", (tester) async {
      late VoidCallback hide;
      await aPage(tester, onOverlayBuilt: (hideOverlay) => hide = hideOverlay);
      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      hide();
      await tester.pump(_fadeDuration ~/ 2);

      expect(find.text("over"), findsOneWidget);
    });

    testWidgets("shows nothing when the page it is given has no overlay", (tester) async {
      await aPage(tester, onOverlayBuilt: (hide) {}, withOverlay: false);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(find.text("over"), findsNothing);
    });

    testWidgets("warns when the page it is given has no overlay", (tester) async {
      await aPage(tester, onOverlayBuilt: (hide) {}, withOverlay: false);

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();

      expect(logger.recordsAtLevel(LogsLevel.warn), hasLength(1));
    });
  });
}
