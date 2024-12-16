// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/src/transitions/route_transition.dart';
import 'package:act_router_manager/src/types/screen_orientation_option.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// This is the result of the call of create page callback
class RoutePageDetails extends Equatable {
  /// This is the transition which overrides the default transition and the route transition
  final RouteTransition? transition;

  /// This is the screen orientation which overrides the default screen orientation and the route
  /// screen orientation
  final ScreenOrientationOption? screenOrientation;

  /// This is the widget built
  final Widget widget;

  /// Class constructor
  const RoutePageDetails({
    required this.widget,
    this.transition,
    this.screenOrientation,
  }) : super();

  @override
  List<Object?> get props => [transition, screenOrientation, widget];
}
