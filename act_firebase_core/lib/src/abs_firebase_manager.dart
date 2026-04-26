// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_firebase_core/src/abs_firebase_service.dart';
import 'package:act_firebase_core/src/models/firebase_manager_config.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Builder of the abstract firebase manager
abstract class AbsFirebaseBuilder<T extends AbsFirebaseManager, C extends AbstractConfigManager>
    extends AbsLifeCycleFactory<T> {
  /// Class constructor
  AbsFirebaseBuilder(super.factory);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager, C];
}

/// This is the abstract firebase manager
abstract class AbsFirebaseManager extends AbsWithLifeCycle {
  /// This is the category for the firebase logs helper
  static const _firebaseLogsCategory = "firebase";

  /// The manager for logs helper
  late final LogsHelper _logsHelper;

  /// List of all the firebase services managed by the class
  late final List<AbsFirebaseService> _firebaseServices;

  /// Get the configuration linked to Firebase
  /// This has to be overridden by the derived class
  @protected
  Future<FirebaseManagerConfig> getFirebaseConfig();

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    final config = await getFirebaseConfig();
    _logsHelper = LogsHelper(
      category: _firebaseLogsCategory,
      minLevel: config.loggerEnabled ? null : LogsLevel.off,
    );

    await Firebase.initializeApp(
      name: config.firebaseAppName,
      options: config.options,
    );

    _firebaseServices = config.firebaseServices;

    for (final service in _firebaseServices) {
      await service.initLifeCycle(
        parentLogsHelper: _logsHelper,
      );
    }
  }

  /// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    for (final service in _firebaseServices) {
      await service.disposeLifeCycle();
    }

    await super.disposeLifeCycle();
  }
}
