// Copyright (c) 2020. BMS Circuits

import 'package:act_global_manager/src/global_manager.dart';
import 'package:flutter/foundation.dart';

import 'dpd_two_manager.dart';
import 'level_two_manager.dart';

class TestGlobalManager extends GlobalManager {
  static TestGlobalManager get instance =>
      GlobalManager.instance as TestGlobalManager;

  static TestGlobalManager staticCreate() {
    GlobalManager.instance = TestGlobalManager.create();
    return instance;
  }

  TestGlobalManager.create() : super.create() {
    init();
  }

  @override
  @mustCallSuper
  void init() {
    super.init();

    registerSingletonAsync<LevelTwoManager>(LevelTwoBuilder(
      dpdOneDepends: DpdTwoManager,
    ));

    registerSingletonAsync<DpdTwoManager>(DpdTwoBuilder());
  }
}
