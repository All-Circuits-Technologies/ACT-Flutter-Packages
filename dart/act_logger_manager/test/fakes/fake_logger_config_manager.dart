// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:act_dart_yaml_utility/act_dart_yaml_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:meta/meta.dart';

/// A configuration manager which declares the variables the loggers of the package read.
class FakeLoggerConfigManager extends AbsCoreConfigManager
    with MixinCslLoggerConfig, MixinLoggerConfig, MixinDefaultLoggerConfig {
  /// The configuration the manager serves.
  final Map<String, dynamic> _configs;

  /// Class constructor
  FakeLoggerConfigManager({this._configs = const {}})
    : super(logger: const SilentLogger(), env: Environment.development);

  /// Parses [content] as the configuration of the application and returns the manager which serves
  /// it, once initialized.
  ///
  /// The caller has to dispose the manager once the test is over.
  static Future<FakeLoggerConfigManager> withContent(String content) async {
    final manager = FakeLoggerConfigManager(configs: YamlFromString.fromYamlMap(content) ?? {});
    await manager.initLifeCycle();

    return manager;
  }

  /// Give the configuration given at construction.
  @override
  @protected
  Future<Map<String, dynamic>> loadConfigs() async => _configs;
}
