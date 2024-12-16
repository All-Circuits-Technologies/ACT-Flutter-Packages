// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_go_router_manager/src/abstract_go_routes_helper.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Builder for creating the AbstractGorouterManager
class AbstractGoRouterBuilder<T extends AbstractGoRouterManager> extends ManagerBuilder<T> {
  /// Class constructor with the class construction
  AbstractGoRouterBuilder({required ClassFactory<T> factory}) : super(factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [
        LoggerManager,
      ];
}

/// The [AbstractGoRouterManager] simplifies [GoRouter]
/// It's recommended to use this class as a singleton with a global manager
abstract class AbstractGoRouterManager extends AbstractManager {
  late final AbstractGoRoutesHelper _goRoutesHelper;
  late final GoRouter _router;
  late final String _initialRoute;

  /// Class constructor
  AbstractGoRouterManager() : super();

  /// The [init] method has to be called to initialize the class
  /// The method will generate the router for GoRouter
  @override
  Future<void> initManager() async {
    List<GoRoute> routesBuilder;

    /// RoutesHelper build
    _goRoutesHelper = await createGoRoutesHelper();

    /// Routes List for GoRouter
    routesBuilder = _goRoutesHelper.getRoutesList();

    /// Initial Route
    _initialRoute = _goRoutesHelper.initialRoute;

    /// GoRouter Build for materialapp
    _router = GoRouter(
      initialLocation: _initialRoute,
      debugLogDiagnostics: _goRoutesHelper.getDebugLogDiagnostics(),
      routes: routesBuilder,
      errorBuilder: errorWidget,
    );
  }

  @protected

  /// RoutesHelper creation method
  Future<AbstractGoRoutesHelper> createGoRoutesHelper();

  /// Getter of the GoRouter router for [MaterialApp.router]
  GoRouter get router => _router;

  /// Getter of the initial Route
  String get initialRoute => _initialRoute;

  /// errorWidget used in case of route not found by GoRouter
  Widget errorWidget(BuildContext context, GoRouterState state) =>
      _goRoutesHelper.getErrorWidget(error: state.error);

  /// Pop all pages and push new one, thanks to its name
  ///
  /// If the page is already in stack, the page isn't rebuilt
  void popAllAndPushNamed(
    String location, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, dynamic> queryParameters = const <String, dynamic>{},
    Object? extra,
  }) {
    var alreadyInLocation = (router.location == location);

    while (!alreadyInLocation && router.canPop()) {
      router.pop();
      alreadyInLocation = (router.location == location);
    }

    if (alreadyInLocation) {
      // Nothing to do
      return;
    }

    router.replaceNamed(
      location,
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      extra: extra,
    );
  }

  /// After calling  [dispose}, you have to call the [init] method if you want to reuse the class.
  @override
  Future<void> dispose() async {
    await super.dispose();
  }
}
