// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_router_manager/act_router_manager.dart';

/// This error is thrown when the [ExpectedType] isn't the expected extra type
class ActNotRightRouteExtraError<ExpectedType> extends ActError {
  /// This allows to add the state that caused the error as context to the error
  final GoRouterState state;

  /// Class constructor
  ActNotRightRouteExtraError({required this.state})
    : super(
        "The ${state.name} page can't be created because we didn't retrieve the "
        "right expected argument of type: $ExpectedType, instead we got: "
        "${state.extra.runtimeType}",
      );
}
