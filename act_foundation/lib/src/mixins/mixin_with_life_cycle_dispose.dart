// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/foundation.dart';

/// This mixin is used to add a default dispose method to classes that do not need any
/// initialization.
mixin MixinWithLifeCycleDispose {
  /// {@template act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  /// Default dispose for the class
  /// {@endtemplate}
  ///
  /// Call `super.disposeLifeCycle()` at the end in the derived class method (unless otherwise
  /// specified by a derived class)
  @mustCallSuper
  Future<void> disposeLifeCycle() async {}
}
