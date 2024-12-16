// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/widgets.dart';

/// Typedef for a manager factory
typedef ClassFactory<S> = S Function();

/// Builder for creating managers
abstract class ManagerBuilder<T extends AbstractManager> {
  /// A factory to create a manager instance
  final ClassFactory<T> factory;

  /// Class constructor
  ManagerBuilder(this.factory);

  /// Asynchronous factory which build and initialize a manager
  Future<T> asyncFactory() async {
    final manager = factory();

    await manager.initManager();

    return manager;
  }

  /// {@template ManagerBuilder.dependsOn}
  /// Abstract method which list the manager dependence on others managers
  /// {@endtemplate}
  @mustCallSuper
  Iterable<Type> dependsOn();
}

/// Abstract class for all the application managers
abstract class AbstractManager {
  /// Default constructor
  AbstractManager();

  /// {@template AbstractManager.initManager}
  /// Asynchronous initialization of the manager
  /// {@endtemplate}
  @mustCallSuper
  Future<void> initManager();

  /// {@template AbstractManager.initAfterView}
  /// Method called asynchronously after the view is initialised
  ///
  /// This [BuildContext] is above the Navigator (therefore it can't be used to access it)
  /// {@endtemplate}
  @mustCallSuper
  Future<void> initAfterView(BuildContext context) async {}

  /// {@template AbstractManager.dispose}
  /// Default dispose for manager
  /// {@endtemplate}
  @mustCallSuper
  Future<void> dispose() async {}
}
