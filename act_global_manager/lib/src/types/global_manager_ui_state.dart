// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/src/types/global_manager_state.dart';

/// This enum represents the state of the global manager related to the UI
enum GlobalManagerUiState with MixinExtendsEnum {
  /// The first widget has been built and the managers have called the
  /// AbsWithLifeCycleAndUi.initAfterView method
  initForWidget(idxToInsertInSharedEnum: 4);

  /// {@macro act_dart_utility.MixinExtendsEnum.idxToInsertInSharedEnum}
  @override
  final int idxToInsertInSharedEnum;

  /// Class constructor
  const GlobalManagerUiState({
    required this.idxToInsertInSharedEnum,
  });

  /// {@macro act_dart_utility.MixinExtendsEnum.getAllColumns}
  static List<Enum> getAllColumns() => MixinExtendsEnum.getAllColumns(
        sharedEnums: GlobalManagerState.values,
        specificEnums: values,
      );
}
