// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// The global manager of an application with a view which overrides nothing.
class _PlainUiGlobalManager extends AbsUiGlobalManager {
  /// Class constructor
  _PlainUiGlobalManager() : super.create();

  /// {@macro act_global_manager.AbsGlobalManager.registerManagers}
  @override
  Future<void> registerManagers() async {}
}

void main() {
  group("AbsUiGlobalManager", () {
    test("is a global manager", () {
      expect(_PlainUiGlobalManager(), isA<AbsGlobalManager>());
    });

    test("has the life cycle of an application with a view", () {
      expect(_PlainUiGlobalManager(), isA<MixinUiGlobalManager>());
    });
  });
}
