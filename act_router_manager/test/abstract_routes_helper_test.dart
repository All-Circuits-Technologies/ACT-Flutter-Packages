// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes/fake_routes.dart';

void main() {
  late FakeExternalLogger logs;
  late FakeRoutesHelper helper;

  setUp(() {
    logs = FakeExternalLogger();
    helper = FakeRoutesHelper(logsHelper: logs.buildHelper(category: "router"));
  });

  group("AbstractRoutesHelper", () {
    test("displays the pages without any transition unless it is told otherwise", () {
      expect(helper.defaultTransition, RouteTransition.none);
    });

    test("lets the pages rotate unless it is told otherwise", () {
      expect(helper.defaultOrientation, ScreenOrientationOption.mayRotate);
    });

    test("knows no error page unless it is given one", () {
      expect(helper.errorRoute, isNull);
    });
  });

  group("AbstractRoutesHelper.onPage", () {
    test("keeps a callback per page", () {
      expect(helper.createPageCallback.keys, containsAll(FakeRoute.values));
    });

    test("keeps the last callback registered for a page", () {
      var called = false;
      helper.onPage(FakeRoute.home, (context, state) {
        called = true;

        return const RoutePageDetails(widget: SizedBox());
      });

      helper.createPageCallback[FakeRoute.home]!(_aContext(), _aState(FakeRoute.home));

      expect(called, isTrue);
    });
  });

  group("AbstractRoutesHelper.onObserver", () {
    test("keeps the observers it is given", () {
      final observer = NavigatorObserver();

      helper.onObserver(observer);

      expect(helper.observers, contains(observer));
    });
  });

  group("AbstractRoutesHelper.getRouteFromPath", () {
    test("returns the page which answers on the path given", () {
      expect(helper.getRouteFromPath("/settings/profile"), FakeRoute.profile);
    });

    test("returns null for a path no page answers on", () {
      expect(helper.getRouteFromPath("/unknown"), isNull);
    });

    test("returns null for the one level path of a nested page", () {
      expect(helper.getRouteFromPath("profile"), isNull);
    });
  });

  group("AbstractRoutesHelper.getRouteFromName", () {
    test("returns the page which carries the name given", () {
      expect(helper.getRouteFromName("profile"), FakeRoute.profile);
    });

    test("returns null for a name no page carries", () {
      expect(helper.getRouteFromName("unknown"), isNull);
    });
  });

  group("AbstractRoutesHelper.getRouteFromState", () {
    test("returns the page named by the state", () {
      expect(helper.getRouteFromState(_aState(FakeRoute.profile)), FakeRoute.profile);
    });

    test("returns the page whose path the state carries when it names none", () {
      expect(
        helper.getRouteFromState(_aStateWithoutName(FakeRoute.profile.path)),
        FakeRoute.profile,
      );
    });

    test("returns null when the state names a page which does not exist", () {
      expect(helper.getRouteFromState(_aStateNamed("unknown")), isNull);
    });
  });

  group("AbstractRoutesHelper.checkAndCastExtra", () {
    test("returns the extra of the state, of the type the page expects", () {
      expect(helper.extraOf(_aState(FakeRoute.home, extra: "an argument")), "an argument");
    });

    test("throws when the state carries no extra", () {
      expect(
        () => helper.extraOf(_aState(FakeRoute.home)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group("AbstractRoutesHelper.checkAndCastNullableExtra", () {
    test("returns the extra of the state", () {
      expect(
        helper.nullableExtraOf(_aState(FakeRoute.home, extra: "an argument")),
        "an argument",
      );
    });

    test("returns null when the state carries no extra", () {
      expect(helper.nullableExtraOf(_aState(FakeRoute.home)), isNull);
    });

    test("throws when the extra is not of the type the page expects", () {
      expect(
        () => helper.nullableExtraOf(_aState(FakeRoute.home, extra: 42)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

/// Builds the state go router gives to a page of [route].
GoRouterState _aState(FakeRoute route, {Object? extra}) => GoRouterState(
  _configuration,
  uri: Uri.parse(route.path),
  matchedLocation: route.path,
  pageKey: ValueKey(route.name),
  name: route.name,
  path: route.path,
  fullPath: route.path,
  pathParameters: const {},
  extra: extra,
);

/// Builds a state which names a page which does not exist.
GoRouterState _aStateNamed(String name) => GoRouterState(
  _configuration,
  uri: Uri.parse("/$name"),
  matchedLocation: "/$name",
  pageKey: ValueKey(name),
  name: name,
  fullPath: "/$name",
  pathParameters: const {},
);

/// Builds a state which names no page but carries a path.
GoRouterState _aStateWithoutName(String path) => GoRouterState(
  _configuration,
  uri: Uri.parse(path),
  matchedLocation: path,
  pageKey: ValueKey(path),
  fullPath: path,
  path: path,
  pathParameters: const {},
);

/// A configuration which is only there because a state needs one.
final _configuration = RouteConfiguration(
  ValueNotifier(
    RoutingConfig(
      routes: [GoRoute(path: "/home", builder: (context, state) => const SizedBox())],
    ),
  ),
  navigatorKey: GlobalKey<NavigatorState>(),
);

/// A context which is only there because a page callback needs one.
BuildContext _aContext() => _FakeContext();

/// A context no page of the test actually reads.
class _FakeContext extends StatelessElement {
  /// Class constructor
  _FakeContext() : super(const _FakeWidget());
}

/// The widget of the context no page of the test actually reads.
class _FakeWidget extends StatelessWidget {
  /// Class constructor
  const _FakeWidget();

  @override
  Widget build(BuildContext context) => const SizedBox();
}
