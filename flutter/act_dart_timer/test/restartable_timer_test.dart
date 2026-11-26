// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_timer/act_dart_timer.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const _duration = Duration(seconds: 10);

void main() {
  group("RestartableTimer start", () {
    test("starts with its creation", () {
      fakeAsync((async) {
        var calls = 0;
        RestartableTimer(_duration, () {
          calls++;
          return true;
        });

        async.elapse(_duration);

        expect(calls, 1);
      });
    });

    test("waits for the first restart to start when it is asked to", () {
      fakeAsync((async) {
        var calls = 0;
        final timer = RestartableTimer(_duration, () {
          calls++;
          return true;
        }, waitNextRestartToStart: true);

        async.elapse(_duration * 2);

        expect(calls, 0);

        timer.restart();
        async.elapse(_duration);

        expect(calls, 1);
      });
    });

    test("is not active before its first restart when it does not start with its creation", () {
      fakeAsync((async) {
        final timer = RestartableTimer(_duration, () => true, waitNextRestartToStart: true);

        async.flushMicrotasks();

        expect(timer.isActive, isFalse);
      });
    });

    test("does not call the callback before its duration has elapsed", () {
      fakeAsync((async) {
        var calls = 0;
        RestartableTimer(_duration, () {
          calls++;
          return true;
        });

        async.elapse(_duration - const Duration(milliseconds: 1));

        expect(calls, 0);
      });
    });
  });

  group("RestartableTimer.isActive", () {
    test("returns true while the timer is running", () {
      fakeAsync((async) {
        final timer = RestartableTimer(_duration, () => true);

        async.elapse(_duration ~/ 2);

        expect(timer.isActive, isTrue);
      });
    });

    test("returns false once the timer has fired", () {
      fakeAsync((async) {
        final timer = RestartableTimer(_duration, () => true);

        async.elapse(_duration);

        expect(timer.isActive, isFalse);
      });
    });

    test("stays true between two automatic restarts", () {
      fakeAsync((async) {
        final timer = RestartableTimer.autoRestart(_duration, () => true);

        async.elapse(_duration * 2);

        expect(timer.isActive, isTrue);
      });
    });
  });

  group("RestartableTimer.tick", () {
    test("starts at zero", () {
      fakeAsync((async) {
        final timer = RestartableTimer(_duration, () => true);

        async.flushMicrotasks();

        expect(timer.tick, 0);
      });
    });

    test("counts the timeouts", () {
      fakeAsync((async) {
        final timer = RestartableTimer.autoRestart(_duration, () => true);

        async.elapse(_duration * 3);

        expect(timer.tick, 3);
      });
    });

    test("survives a restart", () {
      fakeAsync((async) {
        final timer = RestartableTimer(_duration, () => true);

        async.elapse(_duration);
        timer.restart();
        async.elapse(_duration);

        expect(timer.tick, 2);
      });
    });
  });

  group("RestartableTimer.restart", () {
    test("calls the callback again after a timeout", () {
      fakeAsync((async) {
        var calls = 0;
        final timer = RestartableTimer(_duration, () {
          calls++;
          return true;
        });

        async.elapse(_duration);
        timer.restart();
        async.elapse(_duration);

        expect(calls, 2);
      });
    });

    test("counts the whole duration again from the restart", () {
      fakeAsync((async) {
        var calls = 0;
        final timer = RestartableTimer(_duration, () {
          calls++;
          return true;
        });

        async.elapse(_duration ~/ 2);
        timer.restart();
        async.elapse(_duration ~/ 2);

        expect(calls, 0);

        async.elapse(_duration ~/ 2);

        expect(calls, 1);
      });
    });

    test("restarts a cancelled timer", () {
      fakeAsync((async) {
        var calls = 0;
        final timer = RestartableTimer(_duration, () {
          calls++;
          return true;
        })..cancel();

        timer.restart();
        async.elapse(_duration);

        expect(calls, 1);
      });
    });
  });

  group("RestartableTimer.cancel", () {
    test("prevents the callback from being called", () {
      fakeAsync((async) {
        var calls = 0;
        RestartableTimer(_duration, () {
          calls++;
          return true;
        }).cancel();

        async.elapse(_duration * 2);

        expect(calls, 0);
      });
    });

    test("makes the timer inactive", () {
      fakeAsync((async) {
        final timer = RestartableTimer(_duration, () => true)..cancel();

        async.flushMicrotasks();

        expect(timer.isActive, isFalse);
      });
    });

    test("stops a timer which restarts by itself", () {
      fakeAsync((async) {
        var calls = 0;
        final timer = RestartableTimer.autoRestart(_duration, () {
          calls++;
          return true;
        });

        async.elapse(_duration);
        timer.cancel();
        async.elapse(_duration * 3);

        expect(calls, 1);
      });
    });

    test("keeps the number of timeouts already counted", () {
      fakeAsync((async) {
        final timer = RestartableTimer(_duration, () => true);

        async.elapse(_duration);
        timer.cancel();
        async.flushMicrotasks();

        expect(timer.tick, 1);
      });
    });
  });

  group("RestartableTimer.reset", () {
    test("prevents the callback from being called", () {
      fakeAsync((async) {
        var calls = 0;
        RestartableTimer(_duration, () {
          calls++;
          return true;
        }).reset();

        async.elapse(_duration * 2);

        expect(calls, 0);
      });
    });

    test("forgets the number of timeouts already counted", () {
      fakeAsync((async) {
        final timer = RestartableTimer(_duration, () => true);

        async.elapse(_duration);
        timer.reset();
        async.flushMicrotasks();

        expect(timer.tick, 0);
      });
    });
  });

  group("RestartableTimer automatic restart", () {
    test("calls the callback again at every timeout", () {
      fakeAsync((async) {
        var calls = 0;
        RestartableTimer.autoRestart(_duration, () {
          calls++;
          return true;
        });

        async.elapse(_duration * 3);

        expect(calls, 3);
      });
    });

    test("stops when the callback reports a problem", () {
      fakeAsync((async) {
        var calls = 0;
        RestartableTimer.autoRestart(_duration, () {
          calls++;
          return calls < 2;
        });

        async.elapse(_duration * 5);

        expect(calls, 2);
      });
    });

    test("becomes inactive when the callback reports a problem", () {
      fakeAsync((async) {
        final timer = RestartableTimer.autoRestart(_duration, () => false);

        async.elapse(_duration);

        expect(timer.isActive, isFalse);
      });
    });

    test("waits for an asynchronous callback before restarting", () {
      fakeAsync((async) {
        var calls = 0;
        RestartableTimer.autoRestart(_duration, () async {
          calls++;
          await Future<void>.delayed(_duration);
          return true;
        });

        async.elapse(_duration * 2);

        expect(calls, 1);

        async.elapse(_duration * 2);

        expect(calls, 2);
      });
    });

    test("does not restart by itself when it is not asked to", () {
      fakeAsync((async) {
        var calls = 0;
        RestartableTimer(_duration, () {
          calls++;
          return true;
        });

        async.elapse(_duration * 3);

        expect(calls, 1);
      });
    });

    test("can be turned on after the creation of the timer", () {
      fakeAsync((async) {
        var calls = 0;
        final timer = RestartableTimer(_duration, () {
          calls++;
          return true;
        });

        async.elapse(_duration);
        timer
          ..autoRestart = true
          ..restart();
        async.elapse(_duration * 2);

        expect(calls, 3);
      });
    });
  });
}
