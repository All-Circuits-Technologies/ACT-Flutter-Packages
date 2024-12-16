// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

/// This abstract model contains information to pass to the authentication views when going to
/// those views with the router manager
abstract class AbsAuthPageExtra<T extends MixinRoute,
    AuthResultStatus extends Enum> extends Equatable {
  /// If not null, this is the page to go when the page has succeeded to do what it wanted
  final T? nextRouteWhenSuccess;

  /// If not null, this is the previous error which occurred and led to this page.
  final AuthResultStatus? previousError;

  /// Class constructor
  const AbsAuthPageExtra({
    this.nextRouteWhenSuccess,
    this.previousError,
  });

  /// Class properties
  @override
  @mustCallSuper
  List<Object?> get props => [
        nextRouteWhenSuccess,
        previousError,
      ];
}
