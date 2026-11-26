// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_firebase_core/act_firebase_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// A service of an application which uses one feature of Firebase.
class FakeFirebaseService extends AbsFirebaseService {
  /// The log category the service writes under.
  final String logCategory;

  /// The number of times the service has been initialized.
  int initCount = 0;

  /// The number of times the service has been disposed.
  int disposeCount = 0;

  /// The helper the service builds from the one the manager gives it.
  LogsHelper? logsHelper;

  /// Class constructor
  FakeFirebaseService({this.logCategory = "aService"});

  /// {@macro act_firebase_core.AbsFirebaseService.initLifeCycle}
  @override
  Future<void> initLifeCycle({LogsHelper? parentLogsHelper}) async {
    await super.initLifeCycle();

    initCount++;
    logsHelper = AbsFirebaseService.createLogsHelper(
      logCategory: logCategory,
      parentLogsHelper: parentLogsHelper,
    );
  }

  @override
  Future<void> disposeLifeCycle() async {
    disposeCount++;

    return super.disposeLifeCycle();
  }
}

/// The manager of an application which uses Firebase.
class FakeFirebaseManager extends AbsFirebaseManager {
  /// The configuration the manager reads when it is initialized.
  final FirebaseManagerConfig config;

  /// Class constructor
  FakeFirebaseManager(this.config);

  /// {@macro act_firebase_core.AbsFirebaseManager.getFirebaseConfig}
  @override
  Future<FirebaseManagerConfig> getFirebaseConfig() async => config;
}

/// The builder of the manager of an application which uses Firebase.
class FakeFirebaseBuilder extends AbsFirebaseBuilder<FakeFirebaseManager, AbstractConfigManager> {
  /// Class constructor
  FakeFirebaseBuilder(super.factory);
}
