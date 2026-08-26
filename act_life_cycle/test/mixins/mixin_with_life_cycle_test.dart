// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

/// A class which only takes the default life cycle of the mixin.
class _PlainService with MixinWithLifeCycleDispose, MixinWithLifeCycle {}

/// A class which records the order of the steps it and the mixin run.
class _RecordingService with MixinWithLifeCycleDispose, MixinWithLifeCycle {
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

/// A class whose initialisation fails.
class _FailingService with MixinWithLifeCycleDispose, MixinWithLifeCycle {
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    throw ActMissingConfigException("serverUrl");
  }
}

void main() {
  group("MixinWithLifeCycle.initLifeCycle", () {
    test("completes without doing anything when it is not overridden", () async {
      final service = _PlainService();

      await expectLater(service.initLifeCycle(), completes);
    });

    test("runs the initialisation of the derived class", () async {
      final service = _RecordingService();

      await service.initLifeCycle();

      expect(service.steps, ["init"]);
    });

    test("lets the failure of a derived class reach the caller", () async {
      final service = _FailingService();

      await expectLater(service.initLifeCycle(), throwsA(isA<ActMissingConfigException>()));
    });
  });

  group("MixinWithLifeCycle", () {
    test("gives a dispose to the classes which take it", () async {
      final service = _PlainService();

      await expectLater(service.disposeLifeCycle(), completes);
    });

    test("runs the initialisation before the dispose", () async {
      final service = _RecordingService();

      await service.initLifeCycle();
      await service.disposeLifeCycle();

      expect(service.steps, ["init", "dispose"]);
    });

    test("can be disposed without having been initialised", () async {
      final service = _RecordingService();

      await service.disposeLifeCycle();

      expect(service.steps, ["dispose"]);
    });
  });
}
