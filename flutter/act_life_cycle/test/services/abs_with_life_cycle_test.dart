// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

/// A manager which takes the whole life cycle as it comes.
class _PlainManager extends AbsWithLifeCycle {
  const _PlainManager();
}

/// A manager which records the steps it runs.
class _RecordingManager extends AbsWithLifeCycle {
  final List<String> steps = [];

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    steps.add("init");
  }

  @override
  Future<void> disposeLifeCycle() async {
    steps.add("dispose");
    await super.disposeLifeCycle();
  }
}

void main() {
  group("AbsWithLifeCycle", () {
    test("has both halves of the life cycle", () {
      const manager = _PlainManager();

      expect(manager, isA<MixinWithLifeCycle>());
      expect(manager, isA<MixinWithLifeCycleDispose>());
    });

    test("can be built as a constant", () {
      expect(const _PlainManager(), const _PlainManager());
    });

    test("completes the two steps of its default life cycle", () async {
      const manager = _PlainManager();

      await expectLater(manager.initLifeCycle(), completes);
      await expectLater(manager.disposeLifeCycle(), completes);
    });

    test("runs the steps of a derived class in order", () async {
      final manager = _RecordingManager();

      await manager.initLifeCycle();
      await manager.disposeLifeCycle();

      expect(manager.steps, ["init", "dispose"]);
    });
  });
}
