// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter/foundation.dart';

/// This mixin is used to add life cycle methods to services and managers
mixin MixinWithLifeCycle on MixinWithLifeCycleDispose {
  /// {@template act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  /// Asynchronous initialization of the class.
  /// {@endtemplate}
  ///
  /// Call `super.initLifeCycle()` first in the derived class method (unless otherwise specified by
  /// a derived class)
  @mustCallSuper
  Future<void> initLifeCycle() async {}
}
