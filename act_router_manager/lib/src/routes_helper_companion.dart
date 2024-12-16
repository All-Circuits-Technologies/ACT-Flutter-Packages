// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/src/abstract_routes_helper.dart';
import 'package:act_router_manager/src/models/page_arguments.dart';
import 'package:act_router_manager/src/observers/orientation_observer.dart';
import 'package:act_router_manager/src/transitions/page_fade_transition.dart';
import 'package:act_router_manager/src/transitions/page_no_transition.dart';
import 'package:act_router_manager/src/transitions/page_slide_transition.dart';
import 'package:act_router_manager/src/transitions/route_transition.dart';
import 'package:act_router_manager/src/types/mixin_route.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Companion class for the go routes helper class, only visible in the library
///
/// This contains all the logical methods to process the routes
class RoutesHelperCompanion<T extends MixinRoute> {
  /// This is the routes list created
  List<GoRoute>? _routesList;

  /// The helper class
  final AbstractRoutesHelper<T> helper;

  /// This is the GoRoute list
  List<GoRoute> get routesList {
    _routesList ??= _createRoutesList();
    return _routesList!;
  }

  /// This is the error page builder
  GoRouterWidgetBuilder? get errorPageBuilder {
    if (helper.errorRoute == null) {
      return null;
    }

    return (context, state) =>
        helper.createPageCallback[helper.errorRoute!]!(context, state).widget;
  }

  /// Class constructor
  RoutesHelperCompanion({
    required this.helper,
  }) {
    helper.onObserver(OrientationObserver<T>(helperCompanion: this));
  }

  /// Get the page arguments from name
  ///
  /// Returns null when the name is null or if the route can't be guessed
  PageArguments? getPageArgumentsFromName(String? name) {
    if (name == null) {
      return null;
    }

    PageArguments? argument;
    for (final route in helper.values) {
      if (route.name != name) {
        continue;
      }

      argument = PageArguments(
        route: route,
        screenOrientation: route.screenOrientation ?? helper.defaultOrientation,
      );
    }

    return argument;
  }

  /// Page creation with transitions
  CustomTransitionPage<void> _getPageAndTransition(
    BuildContext context,
    GoRouterState state,
    T route,
  ) {
    /// Page creation
    final result = helper.createPageCallback[route]!(context, state);

    final transition =
        result.transition ?? route.transition ?? helper.defaultTransition;
    final screenOrientation = result.screenOrientation ??
        route.screenOrientation ??
        helper.defaultOrientation;

    final arguments =
        PageArguments(screenOrientation: screenOrientation, route: route);

    /// Fade transition
    if (transition == RouteTransition.fade) {
      return PageFadeTransition(
        key: state.pageKey,
        child: result.widget,
        name: route.name,
        arguments: arguments,
      );

      /// Slide transition
    } else if (transition == RouteTransition.slide) {
      return PageSlideTransition(
        key: state.pageKey,
        child: result.widget,
        name: route.name,
        arguments: arguments,
      );
    }

    /// Default transition = No transition
    return PageNoTransition(
      key: state.pageKey,
      child: result.widget,
      name: route.name,
      arguments: arguments,
    );
  }

  /// Create the routes lists with tree structure
  List<GoRoute> _createRoutesList() {
    if (helper.createPageCallback.length != helper.values.length) {
      helper.logsHelper.e(
          "Some routes haven't been set with the 'on' method; therefore, some "
          "pages won't be displayed correctly");
      throw Exception(
          "Some routes haven't been set with the 'on' method; therefore, some pages "
          "won't be displayed correctly");
    }

    final routesList = <GoRoute>[];
    final myRoutesMap = <T, GoRoute>{};

    // Routes map construction
    for (final route in helper.values) {
      myRoutesMap[route] = GoRoute(
        name: route.name,
        // Need to add a non constant array here, because the routes list will be extended in
        // the application life. Because, the list won't stay empty, we can't initialize the
        // parameter with a constant empty list
        // ignore: prefer_const_literals_to_create_immutables
        routes: [],
        path: route.oneLevelPath,
        pageBuilder: (context, state) =>
            _getPageAndTransition(context, state, route),
      );
    }

    // Final routes list construction
    for (final entry in myRoutesMap.entries) {
      final parentKey = entry.key.parent;
      if (parentKey != null) {
        myRoutesMap[parentKey]!.routes.add(entry.value);
      } else {
        routesList.add(entry.value);
      }
    }

    return routesList;
  }
}
