// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_firebase_core/src/abs_firebase_service.dart';
import 'package:act_firebase_core/src/models/firebase_manager_config.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

/// Builder of the abstract firebase manager
abstract class AbsFirebaseBuilder<T extends AbsFirebaseManager, C extends AbstractConfigManager>
    extends ManagerBuilder<T> {
  /// Class constructor
  AbsFirebaseBuilder(super.factory);

  @override
  Iterable<Type> dependsOn() => [LoggerManager, C];
}

abstract class AbsFirebaseManager extends AbstractManager {
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

  /// Init manager method
  @override
  Future<void> initManager() async {
    final config = await getFirebaseConfig();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _firebaseLogsCategory,
      enableLog: config.loggerEnabled,
    );

    await Firebase.initializeApp(
      name: config.firebaseAppName,
      options: config.options,
    );

    _firebaseServices = config.firebaseServices;

    for (final service in _firebaseServices) {
      await service.initService(
        parentLogsHelper: _logsHelper,
      );
    }
  }

  /// Called after the first widget is built
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);
    for (final service in _firebaseServices) {
      // In that case, the build context can be accessed through async method
      // ignore: use_build_context_synchronously
      await service.initAfterView(context);
    }
  }

  /// Default dispose for manager
  @override
  Future<void> dispose() async {
    await super.dispose();

    for (final service in _firebaseServices) {
      await service.dispose();
    }
  }
}
