// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// A class which only takes the default dispose of the mixin.
class _PlainService with MixinWithLifeCycleDispose {}

/// A class which adds its own clean up before the one of the mixin.
class _ServiceWithCleanUp with MixinWithLifeCycleDispose {
  final List<String> steps = [];

  @override
  Future<void> disposeLifeCycle() async {
    steps.add("own clean up");
    await super.disposeLifeCycle();
    steps.add("mixin clean up");
  }
}

void main() {
  group("MixinWithLifeCycleDispose.disposeLifeCycle", () {
    test("completes without doing anything when it is not overridden", () async {
      final service = _PlainService();

      await expectLater(service.disposeLifeCycle(), completes);
    });

    test("can be called several times", () async {
      final service = _PlainService();

      await service.disposeLifeCycle();

      await expectLater(service.disposeLifeCycle(), completes);
    });

    test("lets a derived class run its own clean up around the one of the mixin", () async {
      final service = _ServiceWithCleanUp();

      await service.disposeLifeCycle();

      expect(service.steps, ["own clean up", "mixin clean up"]);
    });
  });
}
