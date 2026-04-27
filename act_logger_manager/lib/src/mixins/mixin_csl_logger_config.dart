// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_foundation/act_foundation.dart';

/// This describes the expected config variables for the console logger of the logger manager.
mixin MixinCslLoggerConfig on AbstractConfigManager {
  /// Allows to override the LOGS level of the external console logger of the logger manager
  final cslLogLevelEnv = const NotNullParserConfigVar<LogsLevel, String>(
    'logs.console.level',
    defaultValue: LogsLevel.all,
    parser: LogsLevel.parseFromString,
  );

  /// Allows to override the LOGS print in release of logger manager
  final logPrintInReleaseEnv = const NotNullableConfigVar<bool>(
    'logs.console.printInRelease',
    defaultValue: false,
  );
}
