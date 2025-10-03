// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_local_storage_manager/src/models/shared_preferences_item.dart';
import 'package:act_local_storage_manager/src/services/properties_singleton.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// Builder for creating the PropertiesManager
abstract class AbstractPropertiesBuilder<T extends AbstractPropertiesManager>
    extends AbsManagerBuilder<T> {
  /// A factory to create a manager instance
  const AbstractPropertiesBuilder(super.factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// [AbstractPropertiesManager] handles non-secret settings and preferences storage.
///
/// Each supported property is accessible through a public member,
/// which provides a getter and a setter to read from settings and
/// save to settings respectively.
///
/// {@macro act_local_storage_manager.PropertiesSingleton.details}
abstract class AbstractPropertiesManager extends AbsWithLifeCycle {
  /// Tell if it's the first start of the app after install
  final SharedPreferencesItem<bool> _isFirstStart = SharedPreferencesItem<bool>("isFirstStart");

  /// True if it's the first start of the application
  bool isFirstStart;

  /// Builds an instance of [AbstractPropertiesManager].
  ///
  /// You may want to use created instance as a singleton
  /// in order to save memory.
  AbstractPropertiesManager()
      : isFirstStart = true,
        super();

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    PropertiesSingleton.createInstance();

    try {
      isFirstStart = (await _isFirstStart.load()) ?? isFirstStart;
    } catch (error) {
      appLogger().e("An error occurred when trying to get isFirstStart properties : $error");
    }

    // Check if app has already been run
    if (isFirstStart) {
      // Next app start will no more be first one.
      // We keep isFirstStart true so app can say we are currently in the first start
      await _isFirstStart.store(false);
    }
  }

  /// {@template act_local_storage_manager.AbstractPropertiesManager.deleteAll}
  /// Delete all stored properties.
  /// {@endtemplate}
  Future<void> deleteAll() async => PropertiesSingleton.instance.deleteAll();
}
