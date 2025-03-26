// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_router_manager/src/models/route_page_details.dart';
import 'package:act_router_manager/src/transitions/route_transition.dart';
import 'package:act_router_manager/src/types/mixin_route.dart';
import 'package:act_router_manager/src/types/screen_orientation_option.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// This callback is used to create pages when needed.
typedef CreatePageCallback<T extends MixinRoute> = RoutePageDetails Function(
  BuildContext context,
  GoRouterState state,
);

/// Utility methods to manage [MixinRoute] enum
abstract class AbstractRoutesHelper<T extends MixinRoute> {
  /// This is the logs helper linked to the route manager
  final LogsHelper logsHelper;

  /// This is the create page callbacks called when we want to create a page
  final Map<T, CreatePageCallback<T>> createPageCallback;

  /// This is the list of Navigator observers added to the GoRouter
  final List<NavigatorObserver> observers;

  /// This is the list of the [MixinRoute] values (all of them)
  final List<T> values;

  /// This is the initial route
  final T initialRoute;

  /// If given, this is the error route, called when a problem occurred when asking to go in a
  /// non existent page
  final T? errorRoute;

  /// If true we display the diagnostics/debug log of GoRouter
  final bool debugLogDiagnostics;

  /// This is the default transition to use if none are given by page.
  final RouteTransition defaultTransition;

  /// This is the default orientation to use if none are given by page.
  final ScreenOrientationOption defaultOrientation;

  /// Class constructor
  /// [values] has to be filled with the method values of your Enum
  ///
  /// The callbacks [onPage] and [onObserver] has to be called in the constructor of your derived
  /// class
  AbstractRoutesHelper({
    required this.logsHelper,
    required this.values,
    required this.initialRoute,
    this.errorRoute,
    this.debugLogDiagnostics = false,
    this.defaultTransition = RouteTransition.none,
    this.defaultOrientation = ScreenOrientationOption.mayRotate,
  })  : createPageCallback = {},
        observers = [],
        super();

  /// This is used to add a callback for managing a page creation depending of the route
  ///
  /// This has to be called in the derived class constructor
  void onPage(T page, CreatePageCallback<T> pageCreationCallback) {
    createPageCallback[page] = pageCreationCallback;
  }

  /// This is used to add an observer on the Navigator
  ///
  /// This has to be called in the derived class constructor
  void onObserver(NavigatorObserver observer) {
    observers.add(observer);
  }

  /// Get the route from path
  ///
  /// If the route isn't found, this returns null
  T? getRouteFromPath(String path) {
    for (final route in values) {
      if (route.path == path) {
        return route;
      }
    }

    return null;
  }

  /// Get the route from name
  ///
  /// If the route isn't found, this returns null
  T? getRouteFromName(String name) {
    for (final route in values) {
      if (route.name == name) {
        return route;
      }
    }

    return null;
  }

  /// Get the route from state.
  ///
  /// If the [state] name is not null, we search the route by name.
  /// If the [state] name is null, we search the route by path (using [state] fullPath or
  /// [state] path).
  ///
  /// If the route isn't found, this returns null
  T? getRouteFromState(GoRouterState state) {
    T? result;

    final name = state.name;
    if (name != null) {
      result = getRouteFromName(name);
    } else {
      final path = state.fullPath ?? state.path;

      if (path != null) {
        result = getRouteFromPath(path);
      }
    }

    return result;
  }

  /// Check the type of [state] extra object and return the object casted.
  /// The object can't be null.
  @protected
  ExtraType checkAndCastExtra<ExtraType>(GoRouterState state) =>
      _checkAndCastExtraProcess<ExtraType>(state, isNullable: false);

  /// Check the type of [state] extra object and return the object casted.
  /// The object can be null.
  @protected
  ExtraType? checkAndCastNullableExtra<ExtraType>(GoRouterState state) =>
      _checkAndCastExtraProcess<ExtraType?>(state, isNullable: true);

  /// The method checks the type of [state] extra object and return the object casted.
  ///
  /// This is the implementation of [checkAndCastExtra] and [checkAndCastNullableExtra].
  ExtraType _checkAndCastExtraProcess<ExtraType>(
    GoRouterState state, {
    required bool isNullable,
  }) {
    final extra = state.extra;
    final textIfError = "The ${state.name} page can't be created because we didn't retrieve the "
        "right argument";
    final testIsOk = ((isNullable && extra == null) || (extra != null && extra is ExtraType));
    assert(testIsOk, textIfError);

    if (!testIsOk) {
      throw Exception(textIfError);
    }

    return extra as ExtraType;
  }
}
