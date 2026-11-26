// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023, 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/src/mixins/mixin_with_life_cycle.dart';

/// Abstract class for all the application managers and services
abstract class AbsWithLifeCycle with MixinWithLifeCycleDispose, MixinWithLifeCycle {
  /// Default constructor
  const AbsWithLifeCycle();
}
