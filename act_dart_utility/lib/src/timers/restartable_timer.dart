// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/src/timers/interface_restartable_timer.dart';
import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

/// A non-periodic timer that can be restarted any number of times.
///
/// If [autoRestart] is equal to true, the timer restart by itself
class RestartableTimer implements InterfaceRestartableTimer {
  /// The callback called each time the timer raise
  final RestartTimerCallback callback;

  /// True if we need to automatically restart the timer after the callback is called and if it
  /// returns true
  bool autoRestart;

  /// The timer duration
  Duration duration;

  /// The current flutter timer used
  Timer? _timer;

  /// The mutex prevents to cancel the timer while we are calling the callback
  Mutex _mutex;

  /// True if the timer is active.
  /// If [autoRestart] is equals to true, this always returns true except when the timer is
  /// explicitly cancelled or not yet started
  bool _active;

  /// The number of times the [RestartableTimer] has been timeout
  /// This value is only reset to 0, when calling [reset] method
  int _tick;

  /// True if the timer is active.
  /// If [autoRestart] is equals to true, this always returns true except when the timer is
  /// explicitly cancelled or not yet started
  @override
  bool get isActive => _active;

  /// Returns the number of times the [RestartableTimer] has been timeout
  @override
  int get tick => _tick;

  /// Class constructor
  ///
  /// By default, the timer starts with its creation. To prevent that, you may set
  /// [waitNextResetToStart] to true. In that case, you will have to call the restart method for
  /// starting the timer.
  RestartableTimer(
    this.duration,
    this.callback, {
    bool waitNextRestartToStart = false,
    this.autoRestart = false,
  })  : _mutex = Mutex(),
        _active = false,
        _tick = 0 {
    if (!waitNextRestartToStart) {
      restart();
    }
  }

  /// Factory to create a Restartable time which automatically restart the timer at each timeout.
  ///
  /// By default, the timer starts with its creation. To prevent that, you may set
  /// [waitNextResetToStart] to true. In that case, you will have to call the restart method for
  /// starting the timer.
  factory RestartableTimer.autoRestart(
    Duration duration,
    RestartTimerCallback callback, {
    bool waitNextRestartToStart = false,
  }) =>
      RestartableTimer(
        duration,
        callback,
        waitNextRestartToStart: waitNextRestartToStart,
        autoRestart: true,
      );

  /// Call to restart the timer. The timer is cancelled before to be started again.
  ///
  /// In derived classes, do not directly override this method, but [restartWithoutMutex] method.
  ///
  /// This method is protected by an asynchronous mutex; therefore, when this method returns, the
  /// restart process is not finished.
  @override
  void restart() {
    unawaited(_mutex.protect(() async => restartWithoutMutex()));
  }

  /// Call to cancel the timer.
  ///
  /// In derived classes, do not directly override this method, but [cancelWithoutMutex] method.
  ///
  /// This method is protected by an asynchronous mutex; therefore, when this method returns, the
  /// cancel process is not finished.
  @override
  void cancel() {
    unawaited(_mutex.protect(() async => cancelWithoutMutex()));
  }

  /// Call to reset the timer. The method does a cancel and reset all the incremented properties.
  ///
  /// In derived classes, do not directly override this method, but [resetWithoutMutex] method.
  ///
  /// This method is protected by an asynchronous mutex; therefore, when this method returns, the
  /// cancel process is not finished.
  @override
  void reset() {
    unawaited(_mutex.protect(() async => cancelWithoutMutex()));
  }

  /// Call to restart the timer. The timer is cancelled before to be started again.
  ///
  /// This method is not protected by a mutex but need to be called in a mutex protection.
  @protected
  @mustCallSuper
  void restartWithoutMutex() {
    _timer?.cancel();
    _timer = Timer(duration, _onTimeout);
    _active = true;
  }

  /// Call to cancel the timer.
  ///
  /// This method is not protected by a mutex but need to be called in a mutex protection.
  @protected
  @mustCallSuper
  void cancelWithoutMutex() {
    _timer?.cancel();
    _active = false;
  }

  /// Call to reset the timer. The method does a cancel and reset all the incremented properties.
  ///
  /// This method is not protected by a mutex but need to be called in a mutex protection.
  @protected
  @mustCallSuper
  void resetWithoutMutex() {
    cancelWithoutMutex();
    _tick = 0;
  }

  /// Called when the timer raises its timeout
  ///
  /// The method is protected with a mutex.
  Future<void> _onTimeout() => _mutex.protect(() async {
        ++_tick;
        final isOk = await callback();

        if (!autoRestart || !isOk) {
          _active = false;
          return;
        }

        restartWithoutMutex();
      });
}
