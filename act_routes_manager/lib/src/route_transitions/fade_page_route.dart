// Copyright (c) 2020. BMS Circuits

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// This extend [MaterialPageRoute] to create a new type of transition for pages
///
/// This allow to have a [FadeTransition] between pages
class FadePageRoute<T> extends MaterialPageRoute<T> {
  FadePageRoute({
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
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}
