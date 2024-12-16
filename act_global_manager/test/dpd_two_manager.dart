// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dpd_one_manager.dart';

class DpdTwoBuilder extends DpdOneBuilder<DpdTwoManager> {
  DpdTwoBuilder() : super(() => DpdTwoManager());
}

class DpdTwoManager extends DpdOneManager {
  DpdTwoManager() : super();
}
