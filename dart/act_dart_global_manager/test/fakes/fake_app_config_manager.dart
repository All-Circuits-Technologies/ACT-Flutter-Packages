// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:meta/meta.dart';

/// The config manager of an application which only needs the usual variables.
class FakeAppConfigManager extends AbsCoreConfigManager
    with MixinCslLoggerConfig, MixinLoggerConfig, MixinDefaultLoggerConfig {
  /// The configuration the manager serves.
  final Map<String, dynamic> _configs;

  /// Class constructor
  FakeAppConfigManager({this._configs = const {}})
    : super(logger: const SilentLogger(), env: Environment.development);

  /// Serves [configs] as the configuration of the application and returns the manager which reads
  /// it, once initialized.
  ///
  /// The caller has to dispose the manager once the test is over.
  static Future<FakeAppConfigManager> withConfigs(Map<String, dynamic> configs) async {
    final manager = FakeAppConfigManager(configs: configs);
    await manager.initLifeCycle();

    return manager;
  }

  /// Give the configuration given at construction.
  @override
  @protected
  Future<Map<String, dynamic>> loadConfigs() async => _configs;
}
