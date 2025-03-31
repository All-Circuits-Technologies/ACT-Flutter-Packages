// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/widgets.dart';

/// Abstract class for all the application managers
abstract class AbsWithLifeCycle {
  /// Default constructor
  const AbsWithLifeCycle();

  /// {@template act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  /// Asynchronous initialization of the class.
  /// {@endtemplate}
  ///
  /// Call `super.initLifeCycle()` first in the derived class method (unless otherwise specified by
  /// a derived class)
  @mustCallSuper
  Future<void> initLifeCycle() async {}

  /// {@template act_abstract_manager.AbsWithLifeCycle.initAfterView}
  /// Method called asynchronously after the view is initialised
  ///
  /// This [BuildContext] is above the Navigator (therefore it can't be used to access it)
  /// {@endtemplate}
  @mustCallSuper
  Future<void> initAfterView(BuildContext context) async {}

  /// {@template act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  /// Default dispose for manager
  /// {@endtemplate}
  ///
  /// Call `super.disposeLifeCycle()` at the end in the derived class method (unless otherwise
  /// specified by a derived class)
  @mustCallSuper
  Future<void> disposeLifeCycle() async {}
}
