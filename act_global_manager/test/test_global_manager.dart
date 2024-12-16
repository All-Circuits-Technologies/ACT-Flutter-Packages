// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/src/global_manager.dart';
import 'package:flutter/src/widgets/framework.dart';

import 'dpd_two_manager.dart';
import 'level_two_manager.dart';

class TestGlobalManager extends GlobalManager {
  static TestGlobalManager get instance => GlobalManager.instance! as TestGlobalManager;

  static TestGlobalManager staticCreate() {
    GlobalManager.setInstance = TestGlobalManager.create();
    return instance;
  }

  TestGlobalManager.create() : super.create() {
    init();
  }

  @override
  @mustCallSuper
  void init() {
    registerManagerAsync<LevelTwoManager>(LevelTwoBuilder(
      dpdOneDepends: DpdTwoManager,
    ));

    registerManagerAsync<DpdTwoManager>(DpdTwoBuilder());
  }
}
