// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_go_router_manager/src/transitions/page_fade_transition.dart';
import 'package:act_go_router_manager/src/transitions/page_no_transition.dart';
import 'package:act_go_router_manager/src/transitions/page_slide_transition.dart';
import 'package:act_go_router_manager/src/transitions/route_transition.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Represents a Go Route to display
@immutable
class ActGoRoute extends Equatable {
  final String name;
  final String path;
  final String? parent;

  const ActGoRoute({
    required this.name,
    required this.path,
    required this.parent,
  });

  @override
  List<Object?> get props => [name, path, parent];
}

/// Utility methods to manage [ActGoRoute] enum
abstract class AbstractGoRoutesHelper {
  List<GoRoute>? _routesList;

  final Map<String, ActGoRoute> goRoutesList;
  final String initialRoute;
  late final bool? debugLogDiagnostics;
  late final Widget errorWidget;

  final (RouteTransition, Widget) Function(
      BuildContext context, GoRouterState state, ActGoRoute route) createPage;

  /// Class constructor
  /// [goRoutesList] is the different [ActGoRoute] which can be called and displayed
  AbstractGoRoutesHelper({
    required this.goRoutesList,
    required this.initialRoute,
    required this.createPage,
    this.debugLogDiagnostics,
    required this.errorWidget,
  }) : super();

  /// Get the routes list of all the [ActGoRoute] available for [GoRouter]
  List<GoRoute> getRoutesList() {
    if (_routesList == null) {
      final myRoutesMap = <String, GoRoute>{};

      /// Routes map construction
      for (final route in goRoutesList.values) {
        myRoutesMap[route.name] = GoRoute(
          name: route.name,
          // Need to add a non constant array here, because the routes list will be extended in
          // the application life. Because, the list won't stay empty, we can't initialize the
          // parameter with a constant empty list
          // ignore: prefer_const_literals_to_create_immutables
          routes: [],
          path: (route.parent == null) ? "/${route.path}" : route.path,
          pageBuilder: (context, state) => getPageAndTransition(context, state, route),
        );
      }

      _routesList = [];

      /// Final routes list construction
      for (final route2 in myRoutesMap.values) {
        final parentKey = goRoutesList[route2.name]!.parent;
        if (parentKey != null) {
          myRoutesMap[parentKey]!.routes.add(route2);
        } else {
          _routesList!.add(route2);
        }
      }
    }
    return _routesList as List<GoRoute>;
  }

  /// Page creation with transitions
  CustomTransitionPage<void> getPageAndTransition(
    BuildContext context,
    GoRouterState state,
    ActGoRoute route,
  ) {
    /// Page creation
    final (transition, widget) = createPage(context, state, route);

    /// Fade transition
    if (transition == RouteTransition.fade) {
      return PageFadeTransition(
        key: state.pageKey,
        child: widget,
      );

      /// Slide transition
    } else if (transition == RouteTransition.slide) {
      return PageSlideTransition(
        key: state.pageKey,
        child: widget,
      );
    }

    /// Default transition = No transition
    return PageNoTransition(
      key: state.pageKey,
      child: widget,
    );
  }

  /// Get debug Log Diagnostics value for GoRouter
  bool getDebugLogDiagnostics() {
    return debugLogDiagnostics ?? false;
  }

  /// Get error Widget for GoRouter
  Widget getErrorWidget({Exception? error}) {
    return errorWidget;
  }
}
