// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/src/types/mixin_route.dart';
import 'package:act_router_manager/src/types/screen_orientation_option.dart';
import 'package:equatable/equatable.dart';

/// This is the arguments passed to the transition in order to find linked information
class PageArguments<T extends MixinRoute> extends Equatable {
  /// The screen orientation to apply when the page is displayed
  final ScreenOrientationOption screenOrientation;

  /// The route linked to the page
  final T route;

  /// Other arguments if needed
  final Object? otherArguments;

  /// Class constructor
  const PageArguments({
    required this.screenOrientation,
    required this.route,
    this.otherArguments,
  }) : super();

  @override
  List<Object?> get props => [screenOrientation, route, otherArguments];
}
