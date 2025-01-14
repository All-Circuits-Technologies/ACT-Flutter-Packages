// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

/// Called when the timer raises its timeout
///
/// If the method returns false, it means that a problem occurred and we don't to automatically
/// restart the timer (only used if the restartable timer is in auto restart mode).
typedef RestartTimerCallback = FutureOr<bool> Function();

/// Interface for all the restartable timers
abstract interface class InterfaceRestartableTimer implements Timer {
  /// Call to cancel and restart the timer
  void restart();

  /// Reset does a cancel and reset all the increment properties to have e timer fresh as new
  void reset();
}
