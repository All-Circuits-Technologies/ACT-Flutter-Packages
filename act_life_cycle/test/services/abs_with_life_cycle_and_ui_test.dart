// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter_test/flutter_test.dart';

/// A manager which takes the merged life cycle as it comes.
class _UiManager extends AbsWithLifeCycleAndUi {}

void main() {
  group("AbsWithLifeCycleAndUi", () {
    test("merges the manager life cycle and the UI one", () {
      final manager = _UiManager();

      expect(manager, isA<AbsWithLifeCycle>());
      expect(manager, isA<MixinUiLifeCycle>());
    });

    test("completes every step of its default life cycle", () async {
      final manager = _UiManager();

      await expectLater(manager.initLifeCycle(), completes);
      await expectLater(manager.initAfterManagersAndBeforeViews(), completes);
      await expectLater(manager.disposeLifeCycle(), completes);
    });
  });
}
