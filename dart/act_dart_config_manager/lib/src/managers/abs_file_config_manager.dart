// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/src/loaders/file_config_loader.dart';
import 'package:act_dart_config_manager/src/managers/abs_core_config_manager.dart';
import 'package:act_dart_config_manager/src/types/environment.dart';
import 'package:meta/meta.dart';

/// Config manager which reads the configuration from the file system when the application starts.
///
/// It's the manager to derive from in a pure Dart application (a server, a script): it loads the
/// files through [FileConfigLoader], so the configuration can be changed without recompiling the
/// application. The Flutter applications use the `AbstractConfigManager` class of
/// `act_config_manager` instead, which reads the configuration from the assets of the application.
///
/// This class relies on `dart:io`, so it's exported by the `file_config_loader.dart` library and
/// not by the main one.
abstract class AbsFileConfigManager extends AbsCoreConfigManager {
  /// The directory the configuration is read from, or null to use the default one.
  ///
  /// See [FileConfigLoader.loadConfigs] to know how the directory is chosen when it's null.
  final String? configDir;

  /// Builds an instance of [AbsFileConfigManager].
  ///
  /// The configuration is read from [configDir] when it's given. The environment is [env] when
  /// it's given, else the one chosen by [FileConfigLoader.resolveEnvironment].
  AbsFileConfigManager({required super.logger, this.configDir, Environment? env})
    : super(env: env ?? FileConfigLoader.resolveEnvironment());

  /// Load the configuration from the file system.
  @override
  @protected
  Future<Map<String, dynamic>> loadConfigs() =>
      FileConfigLoader.loadConfigs(logger: logger, env: env, configDir: configDir);
}
