// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The asset key of the configuration file the tests serve.
const _configKey = "assets/config/default.yaml";

/// The config manager of an application which only needs the usual variables.
class FakeAppConfigManager extends AbsUsualConfigManager {
  /// Class constructor
  FakeAppConfigManager() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeAppConfigManager> withContent(String content) async {
    FakeAssets.serve({_configKey: content});

    final manager = FakeAppConfigManager();
    await manager.initLifeCycle();

    return manager;
  }
}
