// Copyright (c) 2020. BMS Circuits

import 'package:act_routes_manager/src/route_transitions/route_transition.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents an application route
@immutable
class RouteName<T> extends Equatable {
  final T value;
  final RouteTransition transition;
  final String path;

  RouteName({
    @required this.value,
    @required this.transition,
    @required this.path,
  })  : assert(value != null),
        assert(transition != null),
        assert(path != null),
        super();

  @override
  List<Object> get props => [value, transition, path];
}

/// Contains helpful methods to manage the routes
abstract class AbstractRoutesNameHelper<T> {
  final Set<RouteName<T>> routeNames;

  AbstractRoutesNameHelper({
    @required this.routeNames,
  }) : assert(routeNames != null);

  /// Parse a route path and returns a [RouteNames]
  RouteName parseRoute(String routePath) {
    for (RouteName routeName in routeNames) {
      if (routeName.path == routePath) {
        return routeName;
      }
    }

    return null;
  }
}
