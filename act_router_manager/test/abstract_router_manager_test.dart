// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_routes.dart';

void main() {
  setUp(FakeGlobalManager.install);

  /// Builds the manager of an application and displays its first page.
  Future<FakeRouterManager> pumpManager(WidgetTester tester) async {
    final manager = FakeRouterManager();
    await manager.initLifeCycle();
    await manager.initAfterManagersAndBeforeViews();
    addTearDown(manager.router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: manager.router));
    await tester.pumpAndSettle();

    return manager;
  }

  group("AbstractRouterBuilder", () {
    test("depends on the logger manager", () {
      expect(
        const AbstractRouterBuilder(factory: FakeRouterManager.new).dependsOn(),
        [LoggerManager],
      );
    });
  });

  group("AbstractRouterManager", () {
    testWidgets("displays the page the routes helper starts on", (tester) async {
      await pumpManager(tester);

      expect(find.text("home"), findsOneWidget);
    });

    testWidgets("knows the page it starts on", (tester) async {
      final manager = await pumpManager(tester);

      expect(manager.initialRoute, FakeRoute.home);
    });
  });

  group("AbstractRouterManager.push", () {
    testWidgets("displays the page it is given", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.push(FakeRoute.settings));

      expect(find.text("settings"), findsOneWidget);
    });

    testWidgets("keeps the page it comes from in the stack", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.push(FakeRoute.settings));

      expect(manager.canPop(), isTrue);
    });

    testWidgets("answers only once the page it pushed is popped", (tester) async {
      final manager = await pumpManager(tester);
      var answered = false;
      unawaited(manager.push(FakeRoute.settings).then((_) => answered = true));
      await tester.pumpAndSettle();

      expect(answered, isFalse);

      manager.pop();
      await tester.pumpAndSettle();

      expect(answered, isTrue);
    });

    testWidgets("answers what the page it pushed was popped with", (tester) async {
      final manager = await pumpManager(tester);
      Object? answer;
      unawaited(manager.push<String>(FakeRoute.settings).then((value) => answer = value));
      await tester.pumpAndSettle();

      manager.pop("a result");
      await tester.pumpAndSettle();

      expect(answer, "a result");
    });
  });

  group("AbstractRouterManager.pop", () {
    testWidgets("goes back to the page it comes from", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      manager.pop();
      await tester.pumpAndSettle();

      expect(find.text("home"), findsOneWidget);
    });
  });

  group("AbstractRouterManager.canPop", () {
    testWidgets("returns false on the page the application starts on", (tester) async {
      final manager = await pumpManager(tester);

      expect(manager.canPop(), isFalse);
    });
  });

  group("AbstractRouterManager.replace", () {
    testWidgets("displays the page it is given", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.replace(FakeRoute.settings));

      expect(find.text("settings"), findsOneWidget);
    });

    testWidgets("drops the page it replaces", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      await _goTo(tester, () => manager.replace(FakeRoute.scanner));

      expect(manager.getCurrentNavStack(), [FakeRoute.home, FakeRoute.scanner]);
    });
  });

  group("AbstractRouterManager.getCurrentTopView", () {
    testWidgets("returns the page which is displayed", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.push(FakeRoute.settings));

      expect(manager.getCurrentTopView(), FakeRoute.settings);
    });
  });

  group("AbstractRouterManager.isRouteInNavStack", () {
    testWidgets("returns true for the page which is displayed", (tester) async {
      final manager = await pumpManager(tester);

      expect(manager.isRouteInNavStack(FakeRoute.home), isTrue);
    });

    testWidgets("returns true for a page which is behind the one displayed", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.push(FakeRoute.settings));

      expect(manager.isRouteInNavStack(FakeRoute.home), isTrue);
    });

    testWidgets("returns false for a page which has not been displayed", (tester) async {
      final manager = await pumpManager(tester);

      expect(manager.isRouteInNavStack(FakeRoute.scanner), isFalse);
    });
  });

  group("AbstractRouterManager.getCurrentNavStack", () {
    testWidgets("returns the pages which are stacked, from the oldest one", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.push(FakeRoute.settings));

      expect(manager.getCurrentNavStack(), [FakeRoute.home, FakeRoute.settings]);
    });
  });

  group("AbstractRouterManager.getFirstRouteInNavStack", () {
    testWidgets("returns the oldest of the pages it is given which is stacked", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      expect(
        manager.getFirstRouteInNavStack([FakeRoute.settings, FakeRoute.home]),
        FakeRoute.home,
      );
    });

    testWidgets("returns null when none of the pages given is stacked", (tester) async {
      final manager = await pumpManager(tester);

      expect(manager.getFirstRouteInNavStack([FakeRoute.scanner]), isNull);
    });
  });

  group("AbstractRouterManager.popUntilMatchThis", () {
    testWidgets("goes back to the page it is given", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));
      await _goTo(tester, () => manager.push(FakeRoute.scanner));

      manager.popUntilMatchThis(FakeRoute.home);
      await tester.pumpAndSettle();

      expect(manager.getCurrentTopView(), FakeRoute.home);
    });

    testWidgets("does nothing when the page it is given is the one displayed", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      manager.popUntilMatchThis(FakeRoute.settings);
      await tester.pumpAndSettle();

      expect(manager.getCurrentNavStack(), [FakeRoute.home, FakeRoute.settings]);
    });

    testWidgets("stops on the first page when the one it is given is not stacked", (
      tester,
    ) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      manager.popUntilMatchThis(FakeRoute.scanner);
      await tester.pumpAndSettle();

      expect(manager.getCurrentTopView(), FakeRoute.home);
    });
  });

  group("AbstractRouterManager.popUntilMatchOne", () {
    testWidgets("goes back to the first of the pages it is given it reaches", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));
      await _goTo(tester, () => manager.push(FakeRoute.scanner));

      manager.popUntilMatchOne([FakeRoute.home, FakeRoute.settings]);
      await tester.pumpAndSettle();

      expect(manager.getCurrentTopView(), FakeRoute.settings);
    });
  });

  group("AbstractRouterManager.popUntilMatchThisThenPop", () {
    testWidgets("goes back past the page it is given", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));
      await _goTo(tester, () => manager.push(FakeRoute.scanner));

      await _goTo(tester, () => manager.popUntilMatchThisThenPop(FakeRoute.settings));

      expect(manager.getCurrentTopView(), FakeRoute.home);
    });

    testWidgets("replaces the first page when it cannot go back any further", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(
        tester,
        () => manager.popUntilMatchThisThenPop(
          FakeRoute.home,
          replaceWithIfCannotPop: FakeRoute.settings,
        ),
      );

      expect(manager.getCurrentTopView(), FakeRoute.settings);
    });

    testWidgets("stays on the first page when it has nothing to replace it with", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.popUntilMatchThisThenPop(FakeRoute.home));

      expect(manager.getCurrentTopView(), FakeRoute.home);
    });
  });

  group("AbstractRouterManager.pushAndRemoveUntilMatchThis", () {
    testWidgets("goes back to the page it is given when it is stacked", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      await _goTo(tester, () => manager.pushAndRemoveUntilMatchThis(FakeRoute.home));

      expect(manager.getCurrentNavStack(), [FakeRoute.home]);
    });

    testWidgets("replaces the first page when the page it is given is not stacked", (
      tester,
    ) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      await _goTo(tester, () => manager.pushAndRemoveUntilMatchThis(FakeRoute.scanner));

      expect(manager.getCurrentTopView(), FakeRoute.scanner);
      expect(manager.canPop(), isFalse);
    });
  });

  group("AbstractRouterManager.pushAndRemoveUntilMatchOne", () {
    testWidgets("pushes the page over the first of the other ones it reaches", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));
      await _goTo(tester, () => manager.push(FakeRoute.scanner));

      await _goTo(
        tester,
        () => manager.pushAndRemoveUntilMatchOne(FakeRoute.notFound, [FakeRoute.settings]),
      );

      expect(manager.getCurrentNavStack(), [
        FakeRoute.home,
        FakeRoute.settings,
        FakeRoute.notFound,
      ]);
    });
  });

  group("AbstractRouterManager.pushAndRemoveUntilFirstRoute", () {
    testWidgets("replaces the first page with the one it is given", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      await _goTo(tester, () => manager.pushAndRemoveUntilFirstRoute(FakeRoute.scanner));

      expect(manager.getCurrentTopView(), FakeRoute.scanner);
      expect(manager.canPop(), isFalse);
    });

    testWidgets("does nothing when the first page is already the one it is given", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.pushAndRemoveUntilFirstRoute(FakeRoute.home));

      expect(manager.getCurrentNavStack(), [FakeRoute.home]);
    });
  });

  group("AbstractRouterManager.pushOrJoin", () {
    testWidgets("goes back to the page when it is already stacked", (tester) async {
      final manager = await pumpManager(tester);
      await _goTo(tester, () => manager.push(FakeRoute.settings));

      await _goTo(tester, () => manager.pushOrJoin(FakeRoute.home));

      expect(manager.getCurrentNavStack(), [FakeRoute.home]);
    });

    testWidgets("pushes the page when it is not stacked yet", (tester) async {
      final manager = await pumpManager(tester);

      await _goTo(tester, () => manager.pushOrJoin(FakeRoute.settings));

      expect(manager.getCurrentNavStack(), [FakeRoute.home, FakeRoute.settings]);
    });
  });

  group("AbstractRouterManager.registerRedirect", () {
    testWidgets("accepts the first redirection it is given", (tester) async {
      final manager = await pumpManager(tester);

      expect(manager.registerRedirect(_noRedirection), isTrue);
      expect(manager.hasARouterRedirection, isTrue);
    });

    testWidgets("refuses a second redirection", (tester) async {
      final manager = await pumpManager(tester);
      manager.registerRedirect(_noRedirection);

      expect(manager.registerRedirect(_toHome), isFalse);
    });

    testWidgets("accepts the redirection which is already registered", (tester) async {
      final manager = await pumpManager(tester);
      manager.registerRedirect(_noRedirection);

      expect(manager.registerRedirect(_noRedirection), isTrue);
    });
  });

  group("AbstractRouterManager.unregisterRedirect", () {
    testWidgets("forgets the redirection which was registered", (tester) async {
      final manager = await pumpManager(tester);
      manager.registerRedirect(_noRedirection);

      expect(manager.unregisterRedirect(_noRedirection), isTrue);
      expect(manager.hasARouterRedirection, isFalse);
    });

    testWidgets("accepts to forget a redirection when there is none", (tester) async {
      final manager = await pumpManager(tester);

      expect(manager.unregisterRedirect(_noRedirection), isTrue);
    });

    testWidgets("refuses to forget a redirection which is not the registered one", (tester) async {
      final manager = await pumpManager(tester);
      manager.registerRedirect(_noRedirection);

      expect(manager.unregisterRedirect(_toHome), isFalse);
      expect(manager.hasARouterRedirection, isTrue);
    });
  });

  group("AbstractRouterManager", () {
    testWidgets("displays the page a redirection sends to instead of the one asked for", (
      tester,
    ) async {
      final manager = await pumpManager(tester);
      manager.registerRedirect(_toHome);

      await _goTo(tester, () => manager.push(FakeRoute.settings));

      expect(manager.getCurrentTopView(), FakeRoute.home);
    });

    testWidgets("displays the page asked for when the redirection lets it through", (
      tester,
    ) async {
      final manager = await pumpManager(tester);
      manager.registerRedirect(_noRedirection);

      await _goTo(tester, () => manager.push(FakeRoute.settings));

      expect(manager.getCurrentTopView(), FakeRoute.settings);
    });
  });
}

/// Runs [navigation] and waits for the pages to settle.
///
/// The future of a navigation which pushes a page only answers once that page is popped, so a test
/// which awaited it would never reach its assertions.
Future<void> _goTo(WidgetTester tester, Future<Object?> Function() navigation) async {
  unawaited(navigation());

  await tester.pumpAndSettle();
}

/// A redirection which lets every page through.
Future<FakeRoute?> _noRedirection(
  BuildContext context,
  FakeRoute route,
  GoRouterState state,
) async => null;

/// A redirection which sends every other page back to the first one.
Future<FakeRoute?> _toHome(BuildContext context, FakeRoute route, GoRouterState state) async =>
    (route == FakeRoute.home) ? null : FakeRoute.home;
