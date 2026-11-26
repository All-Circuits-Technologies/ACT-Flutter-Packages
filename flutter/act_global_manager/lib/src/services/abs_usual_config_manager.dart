// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// This is a usual config manager that contains all the expected config variables for the logger
/// manager.
///
/// This class contains the config variables for the usual projects, but you can create your own
/// config manager by extending [AbstractConfigManager] and adding the config variables you need.
abstract class AbsUsualConfigManager extends AbstractConfigManager
    with MixinCslLoggerConfig, MixinLoggerConfig, MixinDefaultLoggerConfig {
  /// Class constructor
  AbsUsualConfigManager({required super.logger, super.configPath});
}
