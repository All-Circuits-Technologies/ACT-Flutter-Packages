// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("LockEntity", () {
    test("is not locked when it is built", () {
      expect(LockEntity().isLocked, isFalse);
    });

    test("does nothing when it is freed without being locked", () {
      final entity = LockEntity();

      expect(entity.freeLock, returnsNormally);
      expect(entity.isLocked, isFalse);
    });
  });

  group("LockUtility.waitAndLock", () {
    test("takes the lock", () async {
      final lock = LockUtility();

      await lock.waitAndLock();

      expect(lock.isLocked, isTrue);
    });

    test("holds the next caller until the lock is freed", () async {
      final lock = LockUtility();
      final entity = await lock.waitAndLock();
      var passed = false;

      unawaited(lock.waitAndLock().then((_) => passed = true));
      await pumpEventQueue();

      expect(passed, isFalse);

      entity.freeLock();
      await pumpEventQueue();

      expect(passed, isTrue);
    });

    test("releases the callers in the order they asked for the lock", () async {
      final lock = LockUtility();
      final entity = await lock.waitAndLock();
      final order = <int>[];

      Future<void> take(int id) async {
        final taken = await lock.waitAndLock();
        order.add(id);
        taken.freeLock();
      }

      unawaited(take(1));
      unawaited(take(2));
      await pumpEventQueue();

      entity.freeLock();
      await pumpEventQueue();

      expect(order, [1, 2]);
    });

    test("lets several callers through when it allows parallel requests", () async {
      final lock = LockUtility(maxParallelRequestsNb: 2);

      await lock.waitAndLock();

      expect(lock.isLocked, isFalse);

      await lock.waitAndLock();

      expect(lock.isLocked, isTrue);
    });
  });

  group("LockUtility.wait", () {
    test("returns at once when nothing holds the lock", () async {
      final lock = LockUtility();

      await expectLater(lock.wait(), completes);
    });

    test("does not take the lock", () async {
      final lock = LockUtility();

      await lock.wait();

      expect(lock.isLocked, isFalse);
    });

    test("waits for the lock to be freed", () async {
      final lock = LockUtility();
      final entity = await lock.waitAndLock();
      var passed = false;

      unawaited(lock.wait().then((_) => passed = true));
      await pumpEventQueue();

      expect(passed, isFalse);

      entity.freeLock();
      await pumpEventQueue();

      expect(passed, isTrue);
    });
  });

  group("LockUtility.protectLock", () {
    test("returns the result of the critical section", () async {
      final lock = LockUtility();

      expect(await lock.protectLock(() async => 42), 42);
    });

    test("frees the lock once the critical section is over", () async {
      final lock = LockUtility();

      await lock.protectLock(() async {});

      expect(lock.isLocked, isFalse);
    });

    test("frees the lock even when the critical section throws", () async {
      final lock = LockUtility();

      await expectLater(
        lock.protectLock(() async => throw Exception("boom")),
        throwsException,
      );

      expect(lock.isLocked, isFalse);
    });

    test("runs the protected sections one after the other", () async {
      final lock = LockUtility();
      final steps = <String>[];

      Future<void> section(String name) => lock.protectLock(() async {
        steps.add("$name in");
        await Future<void>.delayed(const Duration(milliseconds: 10));
        steps.add("$name out");
      });

      await Future.wait([section("a"), section("b")]);

      expect(steps, ["a in", "a out", "b in", "b out"]);
    });

    test("only waits for the lock when it is asked to", () async {
      final lock = LockUtility();

      await lock.protectLock(() async {}, onlyWait: true);

      expect(lock.isLocked, isFalse);
    });
  });

  group("LockUtility.waitAndOrLock", () {
    test("returns the entity which holds the lock", () async {
      final lock = LockUtility();

      final entity = await lock.waitAndOrLock();

      expect(entity, isNotNull);
      expect(entity!.isLocked, isTrue);
    });

    test("returns nothing when it only waits", () async {
      final lock = LockUtility();

      expect(await lock.waitAndOrLock(onlyWait: true), isNull);
    });
  });
}
