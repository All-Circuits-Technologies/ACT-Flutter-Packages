// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'level_one_manager.dart';

class LevelTwoBuilder extends LevelOneBuilder<LevelTwoManager> {
  LevelTwoBuilder({
    required Type dpdOneDepends,
  }) : super(
          () => LevelTwoManager(),
          dpdOneDepends: dpdOneDepends,
        );
}

class LevelTwoManager extends LevelOneManager {
  static const int cstMagicNumber = 32;

  LevelTwoManager() : super(magicNumber: cstMagicNumber);
}
