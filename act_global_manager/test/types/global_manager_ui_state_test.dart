// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/src/types/global_manager_state.dart';
import 'package:act_global_manager/src/types/global_manager_ui_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("GlobalManagerUiState.getAllColumns", () {
    test("adds the state of the first widget after the states of an application", () {
      expect(GlobalManagerUiState.getAllColumns(), [
        GlobalManagerState.notCreated,
        GlobalManagerState.created,
        GlobalManagerState.startInit,
        GlobalManagerState.allReady,
        GlobalManagerUiState.initForWidget,
      ]);
    });

    test("keeps the states of an application untouched", () {
      GlobalManagerUiState.getAllColumns();

      expect(GlobalManagerState.values.length, 4);
    });
  });

  group("GlobalManagerUiState", () {
    test("comes after the last state of an application", () {
      expect(
        GlobalManagerUiState.initForWidget.idxToInsertInSharedEnum,
        GlobalManagerState.values.length,
      );
    });
  });
}
