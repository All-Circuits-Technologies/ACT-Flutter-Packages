// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_router_manager/src/models/page_arguments.dart';
import 'package:act_router_manager/src/routes_helper_companion.dart';
import 'package:act_router_manager/src/types/mixin_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// This observer is used to update the screen orientation depending of the current top page
class OrientationObserver<T extends MixinRoute> extends NavigatorObserver {
  /// The helper companion
  final RoutesHelperCompanion<T> _helperCompanion;

  /// Class constructor
  OrientationObserver({required RoutesHelperCompanion<T> helperCompanion})
      : _helperCompanion = helperCompanion,
        super();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!route.isCurrent) {
      // Nothing to do
      return;
    }

    unawaited(_setOrientation(route));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (!(newRoute?.isCurrent ?? false)) {
      // Nothing to do
      return;
    }

    unawaited(_setOrientation(newRoute));
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!route.isCurrent) {
      // Nothing to do
      return;
    }

    unawaited(_setOrientation(previousRoute));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (!route.isCurrent) {
      // Nothing to do
      return;
    }

    unawaited(_setOrientation(previousRoute));
  }

  /// Get the page arguments depending of the [route] given. Null if nothing has been found.
  PageArguments? _getPageArguments(Route<dynamic> route) {
    final arguments = route.settings.arguments;

    if (arguments is PageArguments) {
      return arguments;
    }

    // In that case we try to rebuild the page arguments from the route
    return _helperCompanion.getPageArgumentsFromName(route.settings.name);
  }

  /// Set the current preferred orientations for the application
  Future<void> _setOrientation(Route<dynamic>? route) async {
    var option = _helperCompanion.helper.defaultOrientation;

    if (route == null) {
      // Nothing to do
    } else {
      final arguments = _getPageArguments(route);

      if (arguments != null) {
        option = arguments.screenOrientation;
      }
    }

    return SystemChrome.setPreferredOrientations(option.orientations);
  }
}
