// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/src/types/global_manager_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("GlobalManagerState", () {
    test("lists the states in the order an application goes through them", () {
      expect(GlobalManagerState.values, [
        GlobalManagerState.notCreated,
        GlobalManagerState.created,
        GlobalManagerState.startInit,
        GlobalManagerState.allReady,
      ]);
    });
  });
}
