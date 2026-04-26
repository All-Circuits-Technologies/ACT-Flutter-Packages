// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/src/types/ext_logs_level.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:logger/logger.dart';

/// This is the default log filter used with the Logger package.
class DefaultLogFilter extends LogFilter {
  /// True if the application has been built in release mode
  static const bool isRelease = foundation.kReleaseMode;

  /// {@template act_logger_manager.DefaultLogFilter.printLogInRelease}
  /// True to print the app log in the logcat in release
  /// {@endtemplate}
  bool printLogInRelease;

  /// The minimum level of logs to print. Logs with a level lower than this will not be printed.
  ///
  /// If [level] is null, all logs will be printed.
  LogsLevel get minLevel => ExtLogsLevel.fromLoggerLevel(level ?? Level.all);

  /// Set the minimum level of logs to print. Logs with a level lower than this will not be printed.
  set minLevel(LogsLevel value) => level = value.toLoggerLevel;

  /// Class constructor
  DefaultLogFilter({
    this.printLogInRelease = false,
    LogsLevel minLevel = LogsLevel.all,
  }) : super() {
    level = minLevel.toLoggerLevel;
  }

  /// Test if the log should be printed or not
  @override
  bool shouldLog(LogEvent event) =>
      ((!isRelease || printLogInRelease) && (level == null || event.level.index >= level!.index));
}
