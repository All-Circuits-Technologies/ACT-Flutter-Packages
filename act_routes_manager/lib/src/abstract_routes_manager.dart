// Copyright (c) 2020. BMS Circuits

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_routes_manager/src/route_movement_behavior.dart';
import 'package:act_routes_manager/src/route_transitions/default_page_route.dart';
import 'package:act_routes_manager/src/route_transitions/fade_page_route.dart';
import 'package:act_routes_manager/src/route_transitions/route_transition.dart';
import 'package:act_routes_manager/src/routes_name.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Builder for creating the RoutesManager
abstract class AbstractRoutesBuilder<T extends AbstractRoutesManager>
    extends ManagerBuilder<T> {
  /// Class constructor with the class construction
  AbstractRoutesBuilder({
    ClassFactory<T> factory,
  }) : super(factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// The [RoutesManager] allows to define the widgets linked to the routes and
/// contains helpful methods to go directly to pages
abstract class AbstractRoutesManager<T> extends AbstractManager {
  /// [_defaultPage] is the default page to display when the route is not
  /// known.
  /// It's better to display a real page to user, for instance the home page,
  /// this defaultPage should be never seen by an user, if it is, it means that
  /// a page is missing or not managed.
  static final Widget defaultPage = Container(child: Text("No page found"));

  final GlobalKey<NavigatorState> navigatorKey;

  final AbstractRoutesNameHelper<T> _routesNameHelper;

  _RouteNavigatorObserver _navigatorObserver;

  /// Returns a navigator observer to follow the routes navigation
  ///
  /// This observer has to be attached to the MaterialApp observers
  NavigatorObserver get navObserver => _navigatorObserver;

  /// Class constructor
  AbstractRoutesManager({
    @required AbstractRoutesNameHelper routesNameHelper,
  })  : assert(routesNameHelper != null),
        _routesNameHelper = routesNameHelper,
        navigatorKey = GlobalKey(),
        super();

  /// Initialization manager
  @override
  Future<void> initManager() async {
    _navigatorObserver = _RouteNavigatorObserver();
  }

  /// Defines the first route to display
  String initialRoute();

  @protected
  Widget generatePage(RouteName routeName);

  /// This method manages the display of page thanks to their routes name
  Route<dynamic> generateRoute(RouteSettings settings) {
    RouteName routeName = _routesNameHelper.parseRoute(settings.name);

    if (routeName == null) {
      AppLogger().w("There is no known route named: ${settings.name}, "
          "redirect to the main page");
    }

    Widget page = generatePage(routeName);

    switch (routeName.transition) {
      case RouteTransition.Fade:
        return FadePageRoute(
          settings: settings,
          builder: (context) => page,
        );

      case RouteTransition.Default:
      default:
        return DefaultPageRoute(
          settings: settings,
          builder: (context) => page,
        );
    }
  }

  /// Useful method to go to a specific page.
  ///
  /// The [routeName] parameter describes the page where you want to go.
  /// The [routeBehavior] parameter describes how we want to go to the page
  /// The [arguments] contains the arguments needed by the new page.
  @protected
  Future<void> goToPage(
    RouteName routeName,
    RouteMovementBehavior routeBehavior,
    Object arguments, {
    BuildContext context,
    RoutePredicate predicate,
  }) async {
    assert(routeName != null);

    NavigatorState state;

    if (context == null) {
      state = navigatorKey.currentState;
    } else {
      state = Navigator.of(context);
    }

    String routeNameStr = routeName.path;

    switch (routeBehavior) {
      case RouteMovementBehavior.Push:
        return state.pushNamed(
          routeNameStr,
          arguments: arguments,
        );
      case RouteMovementBehavior.ReplaceCurrent:
        return _replaceIfNeeded(
          state,
          routeNameStr,
          arguments,
        );
      case RouteMovementBehavior.PopAllAndPush:
        return state.pushNamedAndRemoveUntil(
          routeNameStr,
          (route) => false,
          arguments: arguments,
        );
      case RouteMovementBehavior.PopUntilAndPush:
        return state.pushNamedAndRemoveUntil(
          routeNameStr,
          predicate ?? (route) => false,
          arguments: arguments,
        );
      case RouteMovementBehavior.PopAndReplace:
        return _replaceIfNeeded(
          state,
          routeNameStr,
          arguments,
          popCurrentPage: true,
        );
    }
  }

  /// Replace the current page, if only the current page isn't already the one
  /// wanted.
  ///
  /// If [popCurrentPage] equals to true and if we can pop, we pop before
  /// replace the view
  Future<void> _replaceIfNeeded(
    NavigatorState state,
    String routeNameStr,
    Object arguments, {
    bool popCurrentPage = false,
  }) async {
    Route currentRoute = _navigatorObserver.currentRoute;

    if (popCurrentPage && state.canPop()) {
      state.pop();
      currentRoute = _navigatorObserver.currentRoute;
    }

    if (currentRoute != null &&
        currentRoute.settings != null &&
        currentRoute.settings.name == routeNameStr &&
        currentRoute.settings.arguments == arguments) {
      return null;
    }

    return state.pushReplacementNamed(routeNameStr, arguments: arguments);
  }
}

/// Useful class to observer the navigation in the application
class _RouteNavigatorObserver extends NavigatorObserver {
  Route _currentRoute;

  /// Get the current route
  Route get currentRoute => _currentRoute;

  /// Useful to update the current route
  void _updateRoute(Route newRoute) {
    _currentRoute = newRoute;
  }

  /// The [previousRoute] is the route before [route]. If we are here, it means
  /// that [route] has been popped and so the new current route is
  /// [previousRoute]
  @override
  void didPop(Route route, Route previousRoute) {
    _updateRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic> newRoute, Route<dynamic> oldRoute}) {
    _updateRoute(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic> previousRoute) {
    _updateRoute(route);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    _updateRoute(route);
  }
}
