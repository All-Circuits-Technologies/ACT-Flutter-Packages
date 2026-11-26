// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_foundation/act_foundation.dart';

/// This describes the expected config variables for the logger manager.
mixin MixinLoggerConfig on AbsCoreConfigManager {
  /// Allows to override the LOGS level of logger manager
  final logLevelEnv = const NotNullParserConfigVar<LogsLevel, String>(
    'logs.level',
    defaultValue: LogsLevel.warn,
    parser: LogsLevel.parseFromString,
  );
}
