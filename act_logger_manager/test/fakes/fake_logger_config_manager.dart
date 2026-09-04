// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The asset key of the configuration file the tests serve.
const _configKey = "assets/config/default.yaml";

/// A configuration manager which declares the variables the loggers of the package read.
class FakeLoggerConfigManager extends AbstractConfigManager
    with MixinCslLoggerConfig, MixinLoggerConfig, MixinDefaultLoggerConfig {
  /// Class constructor
  FakeLoggerConfigManager() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeLoggerConfigManager> withContent(String content) async {
    FakeAssets.serve({_configKey: content});

    final manager = FakeLoggerConfigManager();
    await manager.initLifeCycle();

    return manager;
  }
}
