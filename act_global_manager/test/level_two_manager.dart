// Copyright (c) 2020. BMS Circuits

import 'package:flutter/foundation.dart';

import 'level_one_manager.dart';

class LevelTwoBuilder extends LevelOneBuilder<LevelTwoManager> {
  LevelTwoBuilder({
    @required Type dpdOneDepends,
  }) : super(
          () => LevelTwoManager(),
          dpdOneDepends: dpdOneDepends,
        );

  @override
  Iterable<Type> dependsOn() => [];
}

class LevelTwoManager extends LevelOneManager {
  static const int cstMagicNumber = 32;

  LevelTwoManager() : super(magicNumber: cstMagicNumber);
}
