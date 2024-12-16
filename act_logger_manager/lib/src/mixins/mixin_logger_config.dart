// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:logger/logger.dart';

/// This describes the expected config variables for the logger manager.
mixin MixinLoggerConfig on AbstractConfigManager {
  /// Allows to override the LOGS level of logger manager
  final logLevelEnv = const NotNullParserConfigVar<Level, String>(
    'logs.level',
    defaultValue: Level.warning,
    parser: _parseLevel,
  );

  /// Allows to override the LOGS print in release of logger manager
  final logPrintInReleaseEnv = const NotNullableConfigVar<bool>(
    'logs.printInRelease',
    defaultValue: false,
  );

  /// This is the parse method for the logs level
  static Level? _parseLevel(String strLevel) {
    Level? parsedLevel;
    final lowerStrLevel = strLevel.toLowerCase();

    for (final value in Level.values) {
      if (value.name.toLowerCase() == lowerStrLevel) {
        parsedLevel = value;
        break;
      }
    }

    return parsedLevel;
  }
}
