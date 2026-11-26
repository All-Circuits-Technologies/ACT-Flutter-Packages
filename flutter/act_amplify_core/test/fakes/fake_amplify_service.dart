// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// A service of an application which uses one feature of the cloud.
class FakeAmplifyService extends AbsAmplifyService {
  /// True when the service refuses to complete the configuration.
  final bool refusesTheConfig;

  /// The number of times the service has been initialized.
  int initCount = 0;

  /// The number of times the service has been disposed.
  int disposeCount = 0;

  /// The logs helper the service has been initialized with.
  LogsHelper? parentLogsHelper;

  /// The configurations the service has been asked to complete.
  final List<AmplifyConfig> updatedConfigs = [];

  /// Class constructor
  FakeAmplifyService({this.refusesTheConfig = false});

  /// {@macro act_amplify_core.AbsAmplifyService.initLifeCycle}
  @override
  Future<void> initLifeCycle({LogsHelper? parentLogsHelper}) async {
    await super.initLifeCycle();

    initCount++;
    this.parentLogsHelper = parentLogsHelper;
  }

  @override
  Future<AmplifyConfig?> updateAmplifyConfig(AmplifyConfig config) async {
    updatedConfigs.add(config);

    return refusesTheConfig ? null : config;
  }

  @override
  Future<List<AmplifyPluginInterface>> getLinkedPluginsList() async => const [];

  @override
  Future<void> disposeLifeCycle() async {
    disposeCount++;

    return super.disposeLifeCycle();
  }
}

/// The manager of an application which uses the cloud.
class FakeAmplifyManager extends AbsAmplifyManager {
  /// The configuration the manager reads when it is initialized.
  final AmplifyManagerConfig config;

  /// Class constructor
  FakeAmplifyManager(this.config);

  /// {@macro act_amplify_core.AbsAmplifyManager.getAmplifyConfig}
  @override
  Future<AmplifyManagerConfig> getAmplifyConfig() async => config;
}

/// The builder of the manager of an application which uses the cloud.
class FakeAmplifyBuilder extends AbsAmplifyBuilder<FakeAmplifyManager, AbstractConfigManager> {
  /// Class constructor
  FakeAmplifyBuilder(super.factory);
}
