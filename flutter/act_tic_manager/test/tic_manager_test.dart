// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_tic_manager/act_tic_manager.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxdart/subjects.dart';

const _interval = Duration(milliseconds: 500);

void main() {
  group("TicGenerator", () {
    test("starts at zero", () {
      fakeAsync((async) {
        final generator = TicGenerator(_interval);

        async.flushMicrotasks();

        expect(generator.stream.value, 0);
      });
    });

    test("increments its counter at every interval", () {
      fakeAsync((async) {
        final generator = TicGenerator(_interval);

        async.elapse(_interval * 3);

        expect(generator.stream.value, 3);
      });
    });

    test("emits a value at every interval", () {
      fakeAsync((async) {
        final generator = TicGenerator(_interval);
        final emitted = <int>[];
        final subscription = generator.stream.listen(emitted.add);

        async.elapse(_interval * 3);

        expect(emitted, [0, 1, 2, 3]);

        unawaited(subscription.cancel());
      });
    });

    test("gives its current value to a listener which comes late", () {
      fakeAsync((async) {
        final generator = TicGenerator(_interval);
        async.elapse(_interval * 2);
        final emitted = <int>[];

        final subscription = generator.stream.listen(emitted.add);
        async.flushMicrotasks();

        expect(emitted, [2]);

        unawaited(subscription.cancel());
      });
    });

    test("does not emit before its first interval has elapsed", () {
      fakeAsync((async) {
        final generator = TicGenerator(_interval);

        async.elapse(_interval - const Duration(milliseconds: 1));

        expect(generator.stream.value, 0);
      });
    });

    test("refuses an interval which is not a duration to wait", () {
      expect(() => TicGenerator(Duration.zero), throwsAssertionError);
      expect(() => TicGenerator(-_interval), throwsAssertionError);
    });
  });

  group("TicModulo", () {
    test("emits once for every given number of source values", () {
      fakeAsync((async) {
        final source = BehaviorSubject<int>.seeded(0);
        final modulo = TicModulo(source.stream, 2);
        final emitted = <int>[];
        final subscription = modulo.stream.listen(emitted.add);
        async.flushMicrotasks();

        for (var value = 1; value <= 4; value++) {
          source.add(value);
        }
        async.flushMicrotasks();

        expect(emitted, [1, 2, 3]);

        unawaited(subscription.cancel());
        unawaited(source.close());
      });
    });

    test("ignores the source values which are not a factor of its modulo", () {
      fakeAsync((async) {
        final source = BehaviorSubject<int>.seeded(1);
        final modulo = TicModulo(source.stream, 3);
        final emitted = <int>[];
        final subscription = modulo.stream.listen(emitted.add);
        async.flushMicrotasks();

        source
          ..add(2)
          ..add(4);
        async.flushMicrotasks();

        expect(emitted, isEmpty);

        unawaited(subscription.cancel());
        unawaited(source.close());
      });
    });

    test("keeps the source and the modulo it is given", () {
      final source = BehaviorSubject<int>.seeded(0);
      final modulo = TicModulo(source.stream, 4);

      expect(modulo.source, source.stream);
      expect(modulo.modulo, 4);

      unawaited(source.close());
    });

    test("refuses a modulo which would divide nothing", () {
      final source = BehaviorSubject<int>.seeded(0);

      expect(() => TicModulo(source.stream, 1), throwsAssertionError);
      expect(() => TicModulo(source.stream, 0), throwsAssertionError);

      unawaited(source.close());
    });
  });

  group("TicManager", () {
    test("is a manager with a life cycle", () {
      fakeAsync((async) {
        expect(TicManager(), isA<AbsWithLifeCycle>());
      });
    });

    test("wraps its counters on an unsigned value of 32 bits", () {
      expect(TicManager.countersMaxValue, 0xffffffff);
    });

    test("increments the fast tic twice a second", () {
      fakeAsync((async) {
        final manager = TicManager();

        async.elapse(const Duration(seconds: 2));

        expect(manager.tic500ms.value, 4);
      });
    });

    test("increments the slow tic once a second", () {
      fakeAsync((async) {
        final manager = TicManager();
        final emitted = <int>[];
        final subscription = manager.tic1s.listen(emitted.add);

        async.elapse(const Duration(seconds: 2));

        expect(emitted, [1, 2, 3]);

        unawaited(subscription.cancel());
      });
    });

    test("keeps the slow tic in step with the fast one", () {
      fakeAsync((async) {
        final manager = TicManager();
        final slowValues = <int>[];
        final fastAtSlow = <int>[];
        final subscription = manager.tic1s.listen((value) {
          slowValues.add(value);
          fastAtSlow.add(manager.tic500ms.value);
        });

        async.elapse(const Duration(seconds: 3));

        expect(fastAtSlow.every((fast) => fast.isEven), isTrue);
        expect(slowValues.length, fastAtSlow.length);

        unawaited(subscription.cancel());
      });
    });
  });

  group("TicBuilder", () {
    test("depends on no other manager", () {
      expect(TicBuilder().dependsOn(), isEmpty);
    });

    test("builds a tic manager", () {
      fakeAsync((async) {
        expect(TicBuilder().factory(), isA<TicManager>());
      });
    });
  });
}
