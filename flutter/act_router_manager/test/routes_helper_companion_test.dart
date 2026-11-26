// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_router_manager/src/models/page_arguments.dart';
import 'package:act_router_manager/src/observers/orientation_observer.dart';
import 'package:act_router_manager/src/routes_helper_companion.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes/fake_routes.dart';

void main() {
  late FakeExternalLogger logs;

  setUp(() => logs = FakeExternalLogger());

  /// Builds the companion of a helper the test configures.
  RoutesHelperCompanion<FakeRoute> aCompanion({
    FakeRoute? errorRoute,
    List<FakeRoute>? configuredPages,
    Map<FakeRoute, RoutePageDetails> overriddenDetails = const {},
  }) => RoutesHelperCompanion<FakeRoute>(
    helper: FakeRoutesHelper(
      logsHelper: logs.buildHelper(category: "router"),
      errorRoute: errorRoute,
      configuredPages: configuredPages,
      overriddenDetails: overriddenDetails,
    ),
  );

  group("RoutesHelperCompanion", () {
    test("watches the navigation to keep the orientation of the pages", () {
      final companion = aCompanion();

      expect(companion.helper.observers, contains(isA<OrientationObserver<FakeRoute>>()));
    });
  });

  group("RoutesHelperCompanion.routesList", () {
    test("puts the pages at the root of the tree in the list", () {
      final companion = aCompanion();

      expect(
        companion.routesList.map((route) => route.name),
        containsAll(["home", "settings", "scanner", "notFound"]),
      );
    });

    test("puts a nested page under its parent instead of in the list", () {
      final companion = aCompanion();

      expect(companion.routesList.map((route) => route.name), isNot(contains("profile")));
      expect(
        companion.routesList
            .firstWhere((route) => route.name == "settings")
            .routes
            .map((route) => (route as GoRoute).name),
        ["profile"],
      );
    });

    test("gives a nested page the path of its own level only", () {
      final companion = aCompanion();

      expect(
        (companion.routesList.firstWhere((route) => route.name == "settings").routes.single
                as GoRoute)
            .path,
        "profile",
      );
    });

    test("builds the list once and keeps it", () {
      final companion = aCompanion();

      expect(companion.routesList, same(companion.routesList));
    });

    test("refuses to build the list when a page has no callback", () {
      final companion = aCompanion(configuredPages: [FakeRoute.home]);

      expect(() => companion.routesList, throwsA(isA<AssertionError>()));
    });
  });

  group("RoutesHelperCompanion.errorPageBuilder", () {
    test("returns nothing when the application declares no error page", () {
      expect(aCompanion().errorPageBuilder, isNull);
    });

    test("returns a builder when the application declares an error page", () {
      expect(aCompanion(errorRoute: FakeRoute.notFound).errorPageBuilder, isNotNull);
    });
  });

  group("RoutesHelperCompanion.getPageArgumentsFromName", () {
    test("returns the arguments of the page which carries the name given", () {
      final companion = aCompanion();

      expect(companion.getPageArgumentsFromName("home")?.route, FakeRoute.home);
    });

    test("returns the orientation the page asks for", () {
      final companion = aCompanion();

      expect(
        companion.getPageArgumentsFromName("scanner")?.screenOrientation,
        ScreenOrientationOption.landscapeOnly,
      );
    });

    test("returns the default orientation for a page which asks for none", () {
      final companion = aCompanion();

      expect(
        companion.getPageArgumentsFromName("home")?.screenOrientation,
        ScreenOrientationOption.mayRotate,
      );
    });

    test("returns null when there is no name to look for", () {
      expect(aCompanion().getPageArgumentsFromName(null), isNull);
    });

    test("returns null for a name no page carries", () {
      expect(aCompanion().getPageArgumentsFromName("unknown"), isNull);
    });
  });

  group("RoutesHelperCompanion", () {
    testWidgets("builds a page without any transition by default", (tester) async {
      final page = await _pumpPage(tester, aCompanion(), FakeRoute.home);

      expect(page, isA<NoTransitionPage<void>>());
    });

    testWidgets("builds a page with the transition its route asks for", (tester) async {
      final page = await _pumpPage(tester, aCompanion(), FakeRoute.profile);

      expect(page, isA<CustomTransitionPage<void>>());
      expect(page, isNot(isA<NoTransitionPage<void>>()));
    });

    testWidgets("builds a page with the transition the callback asks for", (tester) async {
      final companion = aCompanion(
        overriddenDetails: {
          FakeRoute.home: const RoutePageDetails(
            widget: SizedBox(),
            transition: RouteTransition.slide,
          ),
        },
      );

      final page = await _pumpPage(tester, companion, FakeRoute.home);

      expect(page, isNot(isA<NoTransitionPage<void>>()));
    });

    testWidgets("attaches the orientation of the route to the page", (tester) async {
      final page = await _pumpPage(tester, aCompanion(), FakeRoute.scanner);

      expect(
        (page.arguments! as PageArguments).screenOrientation,
        ScreenOrientationOption.landscapeOnly,
      );
    });

    testWidgets("attaches the orientation the callback asks for to the page", (tester) async {
      final companion = aCompanion(
        overriddenDetails: {
          FakeRoute.scanner: const RoutePageDetails(
            widget: SizedBox(),
            screenOrientation: ScreenOrientationOption.portrayOnly,
          ),
        },
      );

      final page = await _pumpPage(tester, companion, FakeRoute.scanner);

      expect(
        (page.arguments! as PageArguments).screenOrientation,
        ScreenOrientationOption.portrayOnly,
      );
    });

    testWidgets("names the page after its route", (tester) async {
      final page = await _pumpPage(tester, aCompanion(), FakeRoute.settings);

      expect(page.name, "settings");
    });
  });
}

/// Displays the page of [route] and returns what the companion built for it.
Future<Page<void>> _pumpPage(
  WidgetTester tester,
  RoutesHelperCompanion<FakeRoute> companion,
  FakeRoute route,
) async {
  final router = GoRouter(
    initialLocation: route.path,
    routes: companion.routesList,
    observers: companion.helper.observers,
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(WidgetsApp.router(routerConfig: router, color: const Color(0xFF000000)));
  await tester.pumpAndSettle();

  return tester
      .widgetList<Navigator>(find.byType(Navigator))
      .expand((navigator) => navigator.pages)
      .last;
}
