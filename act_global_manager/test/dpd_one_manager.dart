// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';

abstract class DpdOneBuilder<T extends DpdOneManager>
    extends ManagerBuilder<T> {
  DpdOneBuilder(super.factory);

  @override
  Iterable<Type> dependsOn() => [];
}

abstract class DpdOneManager extends AbstractManager {
  DpdOneManager() : super();

  @override
  Future<void> initManager() async {}
}
