// Copyright (c) 2020. BMS Circuits

import 'package:act_routes_manager/src/route_transitions/fade_page_route.dart';
import 'package:flutter/material.dart';

/// This extend [MaterialPageRoute] to remove transition when targeting the same
/// page or a [FadePageRoute] (to avoid to have multiple transition behaviors
class DefaultPageRoute<T> extends MaterialPageRoute<T> {
  DefaultPageRoute({
    @required WidgetBuilder builder,
    RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  })  : assert(builder != null),
        super(
          builder: builder,
          settings: settings,
          maintainState: maintainState,
          fullscreenDialog: fullscreenDialog,
        );

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) {
    return super.canTransitionTo(nextRoute) &&
        (nextRoute is! FadePageRoute) &&
        (nextRoute.settings.name != settings.name);
  }

  @override
  bool canTransitionFrom(TransitionRoute<dynamic> fromRoute) {
    return super.canTransitionFrom(fromRoute) &&
        (fromRoute is! FadePageRoute) &&
        (fromRoute.settings.name != settings.name);
  }
}
