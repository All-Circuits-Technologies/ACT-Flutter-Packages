// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/file_config_loader.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// This is a usual config manager that reads its config from the file system and contains all the
/// expected config variables for the logger manager.
///
/// This class contains the config variables for the usual pure Dart hosts (a server, a script), but
/// you can create your own config manager by extending [AbsFileConfigManager] and adding the config
/// variables you need.
///
/// It is the pure Dart counterpart of `AbsUsualConfigManager`, which loads the config from the
/// assets of a Flutter application.
abstract class AbsUsualFileConfigManager extends AbsFileConfigManager
    with MixinCslLoggerConfig, MixinLoggerConfig, MixinDefaultLoggerConfig {
  /// Class constructor
  AbsUsualFileConfigManager({required super.logger, super.configDir, super.env});
}
