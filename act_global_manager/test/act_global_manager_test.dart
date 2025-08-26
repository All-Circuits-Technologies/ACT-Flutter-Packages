// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'test_global_manager.dart';

void main() {
  group('GlobalManager', () {
    test('can create TestGlobalManager instance', () {
      final testManager = TestGlobalManager.staticCreate();
      expect(testManager, isNotNull);
      expect(TestGlobalManager.instance, equals(testManager));
    });

    test('singleton pattern works correctly', () {
      final manager1 = TestGlobalManager.staticCreate();
      final manager2 = TestGlobalManager.instance;
      expect(manager1, equals(manager2));
    });
  });
}
