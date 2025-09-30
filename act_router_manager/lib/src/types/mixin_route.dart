// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/src/transitions/route_transition.dart';
import 'package:act_router_manager/src/types/screen_orientation_option.dart';

/// This mixin is used to define a skeleton for the page route enumeration.
///
/// The manager works with an enum to navigate through pages
mixin MixinRoute on Enum {
  /// This is the path separator between page names
  static const _pathSeparator = "/";

  /// {@template act_router_manager.MixinRoute.parent}
  /// This is the parent of the current enum
  ///
  /// If null it means that the page is at the root of the tree structure
  /// {@endtemplate}
  MixinRoute? get parent;

  /// {@template act_router_manager.MixinRoute.transition}
  /// This allow to precise a specific transition for the page different of the default transition
  ///
  /// If you want to choose the transition when you create the page, you can do it by the object
  /// returned by the `onPage` method of `AbstractRoutesHelper`
  /// {@endtemplate}
  RouteTransition? get transition;

  /// {@template act_router_manager.MixinRoute.screenOrientation}
  /// This allow to precise a specific screen orientation when entering the page, and if not null,
  /// it overrides the default screen orientation.
  ///
  /// If you want to choose the screen orientation when you create the page, you can do it by the
  /// object returned by the `onPage` method of `AbstractRoutesHelper`
  /// {@endtemplate}
  ScreenOrientationOption? get screenOrientation;

  /// Get the complete path of the route (including the parents)
  String get path => _getPath(this);

  /// Get the one level path used by GoRoute
  ///
  /// If it's a root page, it will prefix the route with the path separator (if not, it returns the
  /// name)
  String get oneLevelPath => (parent == null) ? "$_pathSeparator$name" : name;

  /// Get the path of a route, this is a recursive method.
  static String _getPath(MixinRoute route, [String? childPath]) {
    var tmpPath = "$_pathSeparator${route.name}${childPath ?? ""}";

    if (route.parent != null) {
      tmpPath = _getPath(route.parent!, tmpPath);
    }

    return tmpPath;
  }
}
