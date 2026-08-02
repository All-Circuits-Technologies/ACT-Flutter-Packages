// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/act_router_manager.dart';
import 'package:flutter/material.dart';

/// The pages of an application, with a page nested under another one.
enum FakeRoute with MixinRoute {
  /// The page the application starts on.
  home,

  /// A page at the root of the tree.
  settings,

  /// A page nested under [settings], which asks for a transition of its own.
  profile,

  /// A page which asks for an orientation of its own.
  scanner,

  /// The page displayed when a page which does not exist is asked for.
  notFound;

  /// {@macro act_router_manager.MixinRoute.parent}
  @override
  MixinRoute? get parent => switch (this) {
    FakeRoute.profile => FakeRoute.settings,
    _ => null,
  };

  /// {@macro act_router_manager.MixinRoute.transition}
  @override
  RouteTransition? get transition => switch (this) {
    FakeRoute.profile => RouteTransition.fade,
    _ => null,
  };

  /// {@macro act_router_manager.MixinRoute.screenOrientation}
  @override
  ScreenOrientationOption? get screenOrientation => switch (this) {
    FakeRoute.scanner => ScreenOrientationOption.landscapeOnly,
    _ => null,
  };
}

/// The routes of the application under test.
class FakeRoutesHelper extends AbstractRoutesHelper<FakeRoute> {
  /// The pages the helper was asked to create, in the order it created them.
  final List<FakeRoute> createdPages = [];

  /// The details the helper answers with for a page, when the test asks for something else than
  /// what the route says.
  final Map<FakeRoute, RoutePageDetails> overriddenDetails;

  /// Class constructor
  FakeRoutesHelper({
    required super.logsHelper,
    super.initialRoute = FakeRoute.home,
    super.errorRoute,
    super.defaultTransition,
    super.defaultOrientation,
    this.overriddenDetails = const {},
    List<FakeRoute>? configuredPages,
  }) : super(values: FakeRoute.values) {
    for (final page in configuredPages ?? FakeRoute.values) {
      onPage(page, (context, state) {
        createdPages.add(page);

        return overriddenDetails[page] ?? RoutePageDetails(widget: FakePage(route: page));
      });
    }
  }

  /// Reads the extra of [state] the way a page which needs one does.
  String extraOf(GoRouterState state) => checkAndCastExtra<String>(state);

  /// Reads the extra of [state] the way a page which may do without one does.
  String? nullableExtraOf(GoRouterState state) => checkAndCastNullableExtra<String>(state);
}

/// The page a route of the application under test displays.
class FakePage extends StatelessWidget {
  /// The route which displays the page.
  final FakeRoute route;

  /// Class constructor
  const FakePage({required this.route, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(route.name)));
}

/// The router manager of the application under test.
class FakeRouterManager extends AbstractRouterManager<FakeRoute> {
  /// The helper the manager builds its routes from.
  late final FakeRoutesHelper routesHelper;

  /// The helper the test asks the manager to use, if it has one.
  final FakeRoutesHelper? givenHelper;

  /// Class constructor
  FakeRouterManager({this.givenHelper});

  /// {@macro act_router_manager.AbstractRouterManager.createRoutesHelper}
  @override
  Future<AbstractRoutesHelper<FakeRoute>> createRoutesHelper(LogsHelper logsHelper) async {
    routesHelper = givenHelper ?? FakeRoutesHelper(logsHelper: logsHelper);

    return routesHelper;
  }
}
