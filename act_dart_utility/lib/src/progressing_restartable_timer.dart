// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 - 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math';

import 'package:act_dart_utility/src/interface_restartable_timer.dart';
import 'package:act_dart_utility/src/restartable_timer.dart';

/// Defines a callback which returns a factor to apply to the duration depending
/// of the current occurrence of reset
typedef GetDurationFactor = double Function(int occurrenceNth);

/// A non-periodic timer that can be restarted any number of times.
///
/// Once restarted (via [reset]), the timer counts down from the
/// duration calculated with the factor returned by the [factorCallback] given
/// at start.
///
/// The timer duration is equals to:
///
/// Duration = [initDuration] * factor
/// The factor is depending of [_nth]
class ProgressingRestartableTimer extends RestartableTimer {
  /// The initial duration to begin with
  final Duration initDuration;

  /// The max duration which can be waited, if null there is no max limit and if
  /// not null the timer can't wait more than this duration
  final Duration? maxDuration;

  /// The factor callback attached to this timer
  final GetDurationFactor factorCallback;

  /// The current occurrence number, is it the first time the timer is fired?
  int _nth;

  /// Class constructor
  ///
  /// By default, the timer starts with its creation. To prevent that, you may set
  /// [waitNextResetToStart] to true. In that case, you will have to call the restart method for
  /// starting the timer.
  ProgressingRestartableTimer(
    this.initDuration,
    RestartTimerCallback callback,
    this.factorCallback, {
    this.maxDuration,
    super.waitNextRestartToStart = false,
    super.autoRestart = false,
  })  : _nth = 1,
        super(
          initDuration,
          callback,
        );

  /// Class constructor to build a timer which uses the exponential static method
  ///
  /// By default, the timer starts with its creation. To prevent that, you may set
  /// [waitNextResetToStart] to true. In that case, you will have to call the restart method for
  /// starting the timer.
  factory ProgressingRestartableTimer.expFactor(
    Duration initDuration,
    RestartTimerCallback callback, {
    Duration? maxDuration,
    bool waitNextRestartToStart = false,
    bool autoRestart = false,
  }) =>
      ProgressingRestartableTimer(
        initDuration,
        callback,
        getExponentialFactor,
        maxDuration: maxDuration,
        waitNextRestartToStart: waitNextRestartToStart,
        autoRestart: autoRestart,
      );

  /// Class constructor to build a timer which uses the log static method
  ///
  /// By default, the timer starts with its creation. To prevent that, you may set
  /// [waitNextResetToStart] to true. In that case, you will have to call the restart method for
  /// starting the timer.
  factory ProgressingRestartableTimer.logFactor(
    Duration initDuration,
    RestartTimerCallback callback, {
    Duration? maxDuration,
    bool waitNextRestartToStart = false,
    bool autoRestart = false,
  }) =>
      ProgressingRestartableTimer(
        initDuration,
        callback,
        getLogFactor,
        maxDuration: maxDuration,
        waitNextRestartToStart: waitNextRestartToStart,
        autoRestart: autoRestart,
      );

  /// Class constructor to build a timer which uses the simple factor static method
  ///
  /// By default, the timer starts with its creation. To prevent that, you may set
  /// [waitNextResetToStart] to true. In that case, you will have to call the restart method for
  /// starting the timer.
  factory ProgressingRestartableTimer.simpleFactor(
    Duration initDuration,
    RestartTimerCallback callback, {
    Duration? maxDuration,
    bool waitNextRestartToStart = false,
    bool autoRestart = false,
  }) =>
      ProgressingRestartableTimer(
        initDuration,
        callback,
        getSimpleFactor,
        maxDuration: maxDuration,
        waitNextRestartToStart: waitNextRestartToStart,
        autoRestart: autoRestart,
      );

  /// Class constructor to build a timer which uses the none factor static method
  ///
  /// By default, the timer starts with its creation. To prevent that, you may set
  /// [waitNextResetToStart] to true. In that case, you will have to call the restart method for
  /// starting the timer.
  factory ProgressingRestartableTimer.noneFactor(
    Duration initDuration,
    RestartTimerCallback callback, {
    Duration? maxDuration,
    bool waitNextRestartToStart = false,
    bool autoRestart = false,
  }) =>
      ProgressingRestartableTimer(
        initDuration,
        callback,
        getNoneFactor,
        maxDuration: maxDuration,
        waitNextRestartToStart: waitNextRestartToStart,
        autoRestart: autoRestart,
      );

  /// Restarts the timer and calculate the duration to apply (this depending of
  /// the number of times the timer has been reset)
  ///
  /// This restarts the timer even if it has already fired or has been canceled.
  @override
  void restartWithoutMutex() {
    duration = _getDuration(_nth++);
    super.restartWithoutMutex();
  }

  /// Call to reset the timer. The method does a cancel and reset all the incremented properties.
  ///
  /// This method is not protected by a mutex but need to be called in a mutex protection.
  @override
  void resetWithoutMutex() {
    super.resetWithoutMutex();
    _nth = 1;
  }

  /// Defines an exponential factor:
  /// factor = exp([occurrence] -1)
  static double getExponentialFactor(int occurrence) => exp(occurrence - 1);

  /// Defines a logarithm factor:
  /// factor = log([occurrence])
  static double getLogFactor(int occurrence) => log(occurrence);

  /// Defines a simple factor:
  /// factor = [occurrence]
  static double getSimpleFactor(int occurrence) => occurrence.toDouble();

  /// Defines a none factor:
  /// factor = 1
  ///
  /// [occurrence] is not used
  static double getNoneFactor(int occurrence) => 1;

  /// Get the duration to apply to the timer. This is calculated with the
  /// factor method given.
  Duration _getDuration(int occurrence) {
    final duration = initDuration * factorCallback(occurrence);

    if (maxDuration != null) {
      final notNullMaxDuration = maxDuration as Duration;
      if (duration > notNullMaxDuration) {
        // We overflow the max duration, returns maxDuration
        return notNullMaxDuration;
      }
    }

    return duration;
  }
}
