// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../fakes/fake_global_managers.dart';

void main() {
  setUp(() {
    // Sets AbsGlobalManager.instance so appLogger() resolves when a will-show handler fails.
    FakeGlobalManager();
  });

  tearDown(GetIt.instance.reset);

  UiFatalErrorManager buildManager() => UiFatalErrorManager(
    buildFatalErrorPage: (error) => Text("error: $error", textDirection: TextDirection.ltr),
  );

  Future<void> pumpWrappedApp(WidgetTester tester, UiFatalErrorManager manager) => tester.pumpWidget(
    manager.wrapWithFatalErrorWidget(
      child: const Text("the app", textDirection: TextDirection.ltr),
    ),
  );

  group("UiFatalErrorManager", () {
    testWidgets("shows the application while no fatal error occurred", (tester) async {
      final manager = buildManager();

      await pumpWrappedApp(tester, manager);

      expect(find.text("the app"), findsOneWidget);
    });

    testWidgets("shows the fatal error page once a fatal error is displayed", (tester) async {
      final manager = buildManager();
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("boom"));
      await tester.pump();

      expect(find.text("the app"), findsNothing);
      expect(find.textContaining("boom"), findsOneWidget);
    });

    testWidgets("keeps the first fatal error when several occur", (tester) async {
      final manager = buildManager();
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("first"));
      manager.displayFatalErrorPage(StateError("second"));
      await tester.pump();

      expect(find.textContaining("first"), findsOneWidget);
      expect(find.textContaining("second"), findsNothing);
    });

    testWidgets("notifies the will-show handlers with the error", (tester) async {
      final manager = buildManager();
      final seenErrors = <Object>[];
      manager.addFatalErrorWillShowHandler(seenErrors.add);
      await pumpWrappedApp(tester, manager);

      final error = StateError("boom");
      manager.displayFatalErrorPage(error);
      await tester.pump();

      expect(seenErrors, [same(error)]);
    });

    testWidgets("notifies the will-show handlers only once", (tester) async {
      final manager = buildManager();
      var calls = 0;
      manager.addFatalErrorWillShowHandler((error) => calls++);
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("first"));
      manager.displayFatalErrorPage(StateError("second"));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets("stops notifying a removed will-show handler", (tester) async {
      final manager = buildManager();
      var calls = 0;
      void handler(Object error) => calls++;
      manager.addFatalErrorWillShowHandler(handler);
      manager.removeFatalErrorWillShowHandler(handler);
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("boom"));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets("still notifies the other handlers and shows the page when one throws", (
      tester,
    ) async {
      final manager = buildManager();
      final seenBySecond = <Object>[];
      manager.addFatalErrorWillShowHandler((error) => throw StateError("handler boom"));
      manager.addFatalErrorWillShowHandler(seenBySecond.add);
      await pumpWrappedApp(tester, manager);

      final error = StateError("boom");
      manager.displayFatalErrorPage(error);
      await tester.pump();

      expect(seenBySecond, [same(error)]);
      expect(find.textContaining("boom"), findsOneWidget);
    });

    testWidgets("still shows the page when a handler's future rejects", (tester) async {
      final manager = buildManager();
      manager.addFatalErrorWillShowHandler((error) async => throw StateError("async boom"));
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("boom"));
      await tester.pump();

      expect(find.textContaining("boom"), findsOneWidget);
    });
  });
}
