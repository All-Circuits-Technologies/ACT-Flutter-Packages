// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';

abstract class LevelOneBuilder<T extends LevelOneManager> extends AbsManagerBuilder<T> {
  final Type _depends;

  LevelOneBuilder(
    super.factory, {
    required Type dpdOneDepends,
  }) : _depends = dpdOneDepends;

  @override
  Iterable<Type> dependsOn() => [_depends];
}

abstract class LevelOneManager extends AbsWithLifeCycle {
  final int magicNumber;

  LevelOneManager({
    required this.magicNumber,
  }) : super();
}
