// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';

/// This error is thrown when a dead loop is detected while registering a manager.
class ActManagerRegisteringDeadLoopError extends ActError {
  /// Class constructor
  ActManagerRegisteringDeadLoopError({required List<Type> involvedManagers})
    : super("Dead loop detected while registering manager: $involvedManagers");

  /// This trap forcibly crashes the app (in debug mode) when a dead loop is detected while
  /// registering the managers, and throws an [ActManagerRegisteringDeadLoopError] in release mode.
  static Never crash({required List<Type> involvedManagers}) {
    final error = ActManagerRegisteringDeadLoopError(involvedManagers: involvedManagers);
    assert(false, error.message);
    throw error;
  }
}
