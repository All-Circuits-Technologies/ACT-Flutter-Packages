// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:math';

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
class ProgressingRestartableTimer implements Timer {
  /// The initial duration to begin with
  final Duration initDuration;

  /// The max duration which can be waited, if null there is no max limit and if
  /// not null the timer can't wait more than this duration
  final Duration? maxDuration;

  /// The callback called each time the timer raise
  final ZoneCallback zoneCallback;

  /// The factor callback attached to this timer
  final GetDurationFactor factorCallback;

  Timer? _timer;

  /// The current occurrence number, is it the first time the timer is fired?
  late int _nth;

  /// Class constructor
  ///
  /// If [waitNextResetToStart] equals to true, the timer won't be started, to
  /// start it you will need to call the reset method
  ProgressingRestartableTimer(
    this.initDuration,
    this.zoneCallback,
    this.factorCallback, {
    this.maxDuration,
    bool waitNextResetToStart = false,
  }) {
    _init(waitNextResetToStart);
  }

  /// Class constructor to build a timer which uses the exponential static
  /// method
  ProgressingRestartableTimer.expFactor(
    this.initDuration,
    this.zoneCallback, {
    this.maxDuration,
    bool waitNextResetToStart = false,
  }) : factorCallback = getExponentialFactor {
    _init(waitNextResetToStart);
  }

  /// Class constructor to build a timer which uses the log static method
  ProgressingRestartableTimer.logFactor(
    this.initDuration,
    this.zoneCallback, {
    this.maxDuration,
    bool waitNextResetToStart = false,
  }) : factorCallback = getLogFactor {
    _init(waitNextResetToStart);
  }

  /// Class constructor to build a timer which uses the simple factor static
  /// method
  ProgressingRestartableTimer.simpleFactor(
    this.initDuration,
    this.zoneCallback, {
    this.maxDuration,
    bool waitNextResetToStart = false,
  }) : factorCallback = getSimpleFactor {
    _init(waitNextResetToStart);
  }

  /// Class constructor to build a timer which uses the none factor static
  /// method
  ProgressingRestartableTimer.noneFactor(
    this.initDuration,
    this.zoneCallback, {
    this.maxDuration,
    bool waitNextResetToStart = false,
  }) : factorCallback = getNoneFactor {
    _init(waitNextResetToStart);
  }

  /// Init the timer
  ///
  /// If [waitNextResetToStart] equals to false, the timer won't start
  void _init(bool waitNextResetToStart) {
    _nth = 1;

    if (!waitNextResetToStart) {
      reset();
    }
  }

  /// Returns true if the timer is currently activated
  @override
  bool get isActive => _timer?.isActive ?? false;

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

  /// Defines an exponential factor:
  /// factor = exp([occurrence] -1)
  static double getExponentialFactor(int occurrence) {
    return exp(occurrence - 1);
  }

  /// Defines a logarithm factor:
  /// factor = log([occurrence])
  static double getLogFactor(int occurrence) {
    return log(occurrence);
  }

  /// Defines a simple factor:
  /// factor = [occurrence]
  static double getSimpleFactor(int occurrence) {
    return occurrence.toDouble();
  }

  /// Defines a none factor:
  /// factor = 1
  ///
  /// [occurrence] is not used
  static double getNoneFactor(int occurrence) {
    return 1;
  }

  /// Restarts the timer and calculate the duration to apply (this depending of
  /// the number of times the timer has been reset)
  ///
  /// This restarts the timer even if it has already fired or has been canceled.
  void reset() {
    _timer?.cancel();
    _timer = Timer(_getDuration(_nth++), zoneCallback);
  }

  /// Cancel the current timer
  @override
  void cancel() {
    _timer?.cancel();
  }

  /// The number of durations preceding the most recent timer event on the most
  /// recent countdown.
  ///
  /// Calls to [reset] will also reset the tick so subsequent tick values may
  /// not be strictly larger than previous values.
  @override
  int get tick => _timer?.tick ?? 0;
}
