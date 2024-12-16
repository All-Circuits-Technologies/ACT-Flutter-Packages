// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/src/abstract_routes_helper.dart';
import 'package:act_router_manager/src/routes_helper_companion.dart';
import 'package:act_router_manager/src/types/mixin_route.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// This function allows to register router redirection
/// If the function returns null, it means that there is nothing to do
/// If the function returns a non null route:
///   - it means that we want to redirect to this page,
///   - be aware that the new view replaces the one wanted (therefore, the route tested won't be
///     built and displayed),
///   - this method will be recalled with the new view we ask (so be careful to not create
///     infinite redirection)
typedef RouterRedirect<T extends MixinRoute> = Future<T?> Function(
    BuildContext context, T route, GoRouterState state);

/// Builder for creating the AbstractGorouterManager
class AbstractRouterBuilder<M extends AbstractRouterManager> extends ManagerBuilder<M> {
  /// Class constructor with the class construction
  AbstractRouterBuilder({
    required ClassFactory<M> factory,
  }) : super(factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [
        LoggerManager,
      ];
}

/// The [AbstractRouterManager] simplifies [GoRouter]
/// It's recommended to use this class as a singleton with a global manager
abstract class AbstractRouterManager<T extends MixinRoute> extends AbstractManager {
  /// The logs category linked to the router manager
  static const _logsCategory = "router";

  /// The logs helper linked to the router manager
  late final LogsHelper _logsHelper;

  /// The linked helper to manage the routes
  late final RoutesHelperCompanion<T> _helperCompanion;

  /// The GoRouter used with manager
  late final GoRouter _router;

  /// Getter of the GoRouter router for [MaterialApp.router]
  GoRouter get router => _router;

  /// Getter of the initial Route
  T get initialRoute => _helperCompanion.helper.initialRoute;

  /// When a new page is asked, this function is called to verify if a redirection is needed or not
  ///
  /// Use the [registerRedirect] method to register a new router redirect. If one already exist,
  /// use [unregisterRedirect] before
  RouterRedirect<T>? _routerRedirect;

  /// Test if a router redirection is already set, or not.
  bool get hasARouterRedirection => _routerRedirect != null;

  /// Class constructor
  AbstractRouterManager() : super();

  /// The [init] method has to be called to initialize the class
  /// The method will generate the router for GoRouter
  @override
  Future<void> initManager() async {
    _logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory);

    // RoutesHelper build
    final helper = await createRoutesHelper(_logsHelper);

    _helperCompanion = RoutesHelperCompanion<T>(helper: helper);

    // GoRouter Build for materialapp
    _router = GoRouter(
      initialLocation: helper.initialRoute.path,
      debugLogDiagnostics: helper.debugLogDiagnostics,
      routes: _helperCompanion.routesList,
      errorBuilder: _helperCompanion.errorPageBuilder,
      observers: helper.observers,
      redirect: _onRedirect,
    );
  }

  /// RoutesHelper creation method
  @protected
  Future<AbstractRoutesHelper<T>> createRoutesHelper(LogsHelper logsHelper);

  /// Pop all pages and push new one, thanks to its route.
  ///
  /// If the page is already in stack, the page isn't rebuilt
  ///
  /// We have developed our own method because GoRouter doesn't support it for now but the flutter
  /// Navigator does.
  Future<Y?> pushAndRemoveUntil<Y extends Object?>(
    T route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async {
    final routePath = route.path;
    var alreadyInLocation = (_getCurrentLocation() == routePath);

    while (!alreadyInLocation && _router.canPop()) {
      _router.pop();
      alreadyInLocation = (_getCurrentLocation() == routePath);
    }

    if (alreadyInLocation) {
      // Nothing to do
      return null;
    }

    return _router.pushReplacementNamed(
      route.name,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// Push new name thanks to its route.
  Future<Y?> push<Y extends Object?>(
    T route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async =>
      _router.pushNamed(
        route.name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );

  /// Pop the top page
  void pop<Y extends Object?>([T? result]) => _router.pop(result);

  /// Test if the current view can be popped
  bool canPop() => _router.canPop();

  /// Replace the top page with the given route
  ///
  /// The GoRouter `replace` method doesn't work with observers, that's why we override the method
  /// here with pushReplacementNamed method
  Future<Y?> replace<Y extends Object?>(
    T route, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) async =>
      _router.pushReplacementNamed(
        route.name,
        pathParameters: pathParameters,
        queryParameters: queryParameters,
        extra: extra,
      );

  /// Get the current top view
  T? getCurrentTopView() => _helperCompanion.helper.getRouteFromPath(_getCurrentLocation());

  /// Register a router redirect callback to be called when a new page is asked.
  ///
  /// Only one callback can be set at the same; therefore, if a callback has already been set, this
  /// returns false
  bool registerRedirect(RouterRedirect<T> routerRedirect) {
    if (routerRedirect == _routerRedirect) {
      // Already set
      return true;
    }

    if (_routerRedirect != null) {
      _logsHelper.w("A redirect is already set, only one is supported at the time");
      return false;
    }

    _routerRedirect = routerRedirect;

    return true;
  }

  /// Unregister the current router redirect callback. The [routerRedirect] parameter is used to
  /// verify that the caller class is the one which has registered the callback.
  ///
  /// Only one callback can be set at the same; therefore, if a callback has already been set and
  /// the callback doesn't match the one in parameter, this returns false
  bool unregisterRedirect(RouterRedirect<T> routerRedirect) {
    if (_routerRedirect == null) {
      // There is nothing to unregister
      return true;
    }

    if (_routerRedirect != routerRedirect) {
      _logsHelper.w("You try to unregister a router redirect which not the one used for now");
      return false;
    }

    _routerRedirect = null;

    return true;
  }

  /// Get current location
  String _getCurrentLocation() {
    final lastMatch = _router.routerDelegate.currentConfiguration.last;
    final matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  /// Called when a new page is asked to be displayed
  ///
  /// If nothing has to be done, returns null. If we want to change the view and go to another view,
  /// returns the path of the new view.
  Future<String?> _onRedirect(BuildContext context, GoRouterState state) async {
    if (_routerRedirect == null) {
      // Nothing to do
      return null;
    }

    final linkedPage = _helperCompanion.helper.getRouteFromState(state);

    if (linkedPage == null) {
      _logsHelper.w("The page: ${state.toString()}, isn't known, we don't manage redirection");
      return null;
    }

    final route = await _routerRedirect!(context, linkedPage, state);

    if (route == null) {
      // Nothing to do
      return null;
    }

    return route.path;
  }

  /// After calling  [dispose}, you have to call the [init] method if you want to reuse the class.
  @override
  Future<void> dispose() async {
    await super.dispose();
  }
}
