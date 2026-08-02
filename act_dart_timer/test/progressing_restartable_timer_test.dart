// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math';

import 'package:act_dart_timer/act_dart_timer.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const _initDuration = Duration(seconds: 10);

/// Returns the moments at which [timerBuilder] fired, over [totalDuration].
///
/// The timer is built with a callback which always reports a success, so a timer which restarts by
/// itself keeps firing until the whole duration has elapsed.
List<Duration> _firedAt(
  ProgressingRestartableTimer Function(RestartTimerCallback callback) timerBuilder, {
  required Duration totalDuration,
}) {
  final firedAt = <Duration>[];

  fakeAsync((async) {
    timerBuilder(() {
      firedAt.add(async.elapsed);
      return true;
    });

    async.elapse(totalDuration);
  });

  return firedAt;
}

void main() {
  group("ProgressingRestartableTimer factors", () {
    test("keeps the duration untouched with the none factor", () {
      expect(ProgressingRestartableTimer.getNoneFactor(1), 1);
      expect(ProgressingRestartableTimer.getNoneFactor(5), 1);
    });

    test("follows the occurrence with the simple factor", () {
      expect(ProgressingRestartableTimer.getSimpleFactor(1), 1);
      expect(ProgressingRestartableTimer.getSimpleFactor(5), 5);
    });

    test("starts at one and grows with the exponential factor", () {
      expect(ProgressingRestartableTimer.getExponentialFactor(1), 1);
      expect(ProgressingRestartableTimer.getExponentialFactor(3), exp(2));
    });

    test("starts at zero and grows with the logarithm factor", () {
      expect(ProgressingRestartableTimer.getLogFactor(1), 0);
      expect(ProgressingRestartableTimer.getLogFactor(3), log(3));
    });
  });

  group("ProgressingRestartableTimer duration", () {
    test("waits the initial duration for its first timeout", () {
      final firedAt = _firedAt(
        (callback) => ProgressingRestartableTimer.simpleFactor(_initDuration, callback),
        totalDuration: _initDuration * 5,
      );

      expect(firedAt, [_initDuration]);
    });

    test("multiplies the initial duration by the factor of the occurrence", () {
      final firedAt = _firedAt(
        (callback) =>
            ProgressingRestartableTimer.simpleFactor(_initDuration, callback, autoRestart: true),
        totalDuration: _initDuration * 10,
      );

      expect(firedAt, [_initDuration, _initDuration * 3, _initDuration * 6, _initDuration * 10]);
    });

    test("keeps the same duration with the none factor", () {
      final firedAt = _firedAt(
        (callback) =>
            ProgressingRestartableTimer.noneFactor(_initDuration, callback, autoRestart: true),
        totalDuration: _initDuration * 3,
      );

      expect(firedAt, [_initDuration, _initDuration * 2, _initDuration * 3]);
    });

    test("waits longer and longer with the exponential factor", () {
      final firedAt = _firedAt(
        (callback) =>
            ProgressingRestartableTimer.expFactor(_initDuration, callback, autoRestart: true),
        totalDuration: _initDuration * 100,
      );

      expect(firedAt.length, greaterThan(2));
      expect(firedAt[1] - firedAt[0], greaterThan(firedAt[0]));
      expect(firedAt[2] - firedAt[1], greaterThan(firedAt[1] - firedAt[0]));
    });

    test("fires at once the first time with the logarithm factor", () {
      final firedAt = _firedAt(
        (callback) => ProgressingRestartableTimer.logFactor(_initDuration, callback),
        totalDuration: _initDuration,
      );

      expect(firedAt, [Duration.zero]);
    });

    test("never waits longer than the maximum duration", () {
      final firedAt = _firedAt(
        (callback) => ProgressingRestartableTimer.simpleFactor(
          _initDuration,
          callback,
          maxDuration: _initDuration * 2,
          autoRestart: true,
        ),
        totalDuration: _initDuration * 9,
      );

      expect(firedAt, [
        _initDuration,
        _initDuration * 3,
        _initDuration * 5,
        _initDuration * 7,
        _initDuration * 9,
      ]);
    });

    test("keeps the computed duration when it stays below the maximum duration", () {
      final firedAt = _firedAt(
        (callback) => ProgressingRestartableTimer.simpleFactor(
          _initDuration,
          callback,
          maxDuration: _initDuration * 100,
          autoRestart: true,
        ),
        totalDuration: _initDuration * 3,
      );

      expect(firedAt, [_initDuration, _initDuration * 3]);
    });
  });

  group("ProgressingRestartableTimer.restart", () {
    test("moves to the next occurrence even without an automatic restart", () {
      final firedAt = <Duration>[];

      fakeAsync((async) {
        final timer = ProgressingRestartableTimer.simpleFactor(_initDuration, () {
          firedAt.add(async.elapsed);
          return true;
        });

        async.elapse(_initDuration);
        timer.restart();
        async.elapse(_initDuration * 2);
      });

      expect(firedAt, [_initDuration, _initDuration * 3]);
    });
  });

  group("ProgressingRestartableTimer.reset", () {
    test("goes back to the initial duration", () {
      final firedAt = <Duration>[];

      fakeAsync((async) {
        final timer = ProgressingRestartableTimer.simpleFactor(
          _initDuration,
          () {
            firedAt.add(async.elapsed);
            return true;
          },
          autoRestart: true,
        );

        async.elapse(_initDuration * 3);
        timer
          ..reset()
          ..restart();
        async.elapse(_initDuration);
      });

      expect(firedAt, [_initDuration, _initDuration * 3, _initDuration * 4]);
    });

    test("stops the timer until it is restarted", () {
      final firedAt = <Duration>[];

      fakeAsync((async) {
        final timer = ProgressingRestartableTimer.noneFactor(
          _initDuration,
          () {
            firedAt.add(async.elapsed);
            return true;
          },
          autoRestart: true,
        );

        async.elapse(_initDuration);
        timer.reset();
        async.elapse(_initDuration * 5);
      });

      expect(firedAt, [_initDuration]);
    });

    test("forgets the number of timeouts already counted", () {
      fakeAsync((async) {
        final timer = ProgressingRestartableTimer.noneFactor(
          _initDuration,
          () => true,
          autoRestart: true,
        );

        async.elapse(_initDuration * 3);
        timer.reset();
        async.flushMicrotasks();

        expect(timer.tick, 0);
      });
    });
  });

  group("ProgressingRestartableTimer start", () {
    test("waits for the first restart to start when it is asked to", () {
      final firedAt = <Duration>[];

      fakeAsync((async) {
        final timer = ProgressingRestartableTimer.simpleFactor(_initDuration, () {
          firedAt.add(async.elapsed);
          return true;
        }, waitNextRestartToStart: true);

        async.elapse(_initDuration * 2);
        timer.restart();
        async.elapse(_initDuration);
      });

      expect(firedAt, [_initDuration * 3]);
    });
  });

  group("ProgressingRestartableTimer automatic restart", () {
    test("stops when the callback reports a problem", () {
      final firedAt = <Duration>[];

      fakeAsync((async) {
        var calls = 0;
        ProgressingRestartableTimer.noneFactor(
          _initDuration,
          () {
            calls++;
            firedAt.add(async.elapsed);
            return calls < 2;
          },
          autoRestart: true,
        );

        async.elapse(_initDuration * 5);
      });

      expect(firedAt, [_initDuration, _initDuration * 2]);
    });
  });
}
