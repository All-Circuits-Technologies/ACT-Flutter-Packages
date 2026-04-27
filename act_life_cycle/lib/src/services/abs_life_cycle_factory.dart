// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023, 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/src/services/abs_with_life_cycle.dart';
import 'package:flutter/foundation.dart' show mustCallSuper;

/// Typedef for a class factory
typedef ClassFactory<S> = S Function();

/// Builder for creating class with life cycle
abstract class AbsLifeCycleFactory<T extends AbsWithLifeCycle> {
  /// A factory to create a class instance
  final ClassFactory<T> factory;

  /// Class constructor
  const AbsLifeCycleFactory(this.factory);

  /// {@template act_life_cycle.AbsLifeCycleFactory.asyncFactory}
  /// Asynchronous factory which build and initialize a manager
  /// {@endtemplate}
  Future<T> asyncFactory() async {
    final manager = factory();

    await manager.initLifeCycle();

    return manager;
  }

  /// {@template act_life_cycle.AbsLifeCycleFactory.dependsOn}
  /// Abstract method which list the manager dependence on others managers
  /// {@endtemplate}
  @mustCallSuper
  Iterable<Type> dependsOn();
}
