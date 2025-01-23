// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/src/logger_manager.dart';
import 'package:logger/logger.dart';

/// Helpful class to manage logs with library and managers
class LogsHelper {
  /// Useful to separate the logs category with subs category
  static const _logsCategorySeparator = "/";

  /// The log category to use when displaying messages from activities
  final String logsCategory;

  /// The logger manager
  final LoggerManager logsManager;

  /// The log level to used when displaying messages from external packages
  final Level _defaultLogLevel;

  /// True if the logs from the module are to be retrieved
  final bool enableLog;

  /// Class constructor
  LogsHelper({
    required this.logsManager,
    required this.logsCategory,
    this.enableLog = true,
  }) : _defaultLogLevel = Level.debug;

  /// Log a message at level [Level.trace], this is an alias of the [LoggerManager] method to add
  /// category in it
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void t(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logsManager.t(message, logsCategory, error, stackTrace);

  /// Log a message at level [Level.debug], this is an alias of the [LoggerManager] method to add
  /// category in it
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logsManager.d(message, logsCategory, error, stackTrace);

  /// Log a message at level [Level.info], this is an alias of the [LoggerManager] method to add
  /// category in it
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logsManager.i(message, logsCategory, error, stackTrace);

  /// Log a message at level [Level.warning], this is an alias of the [LoggerManager] method to add
  /// category in it
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logsManager.w(message, logsCategory, error, stackTrace);

  /// Log a message at level [Level.error], this is an alias of the [LoggerManager] method to add
  /// category in it
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logsManager.e(message, logsCategory, error, stackTrace);

  /// Log a message at level [Level.fatal], this is an alias of the [LoggerManager] method to add
  /// category in it
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logsManager.f(message, logsCategory, error, stackTrace);

  /// Log a message with [level], this is an alias of the [LoggerManager] method to add category in
  /// it
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void log(Level level, dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      logsManager.log(level, message, logsCategory, error, stackTrace);

  /// Useful to log message from external libraries
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void logMessages(dynamic message) => logsManager.log(_defaultLogLevel, message, logsCategory);

  /// This methods allowes to create a logs helper with a sub category: it has the same category,
  /// with an extra sub category.
  /// This call can be chained
  LogsHelper createASubLogsHelper(String subCategory) => LogsHelper(
        logsManager: logsManager,
        enableLog: enableLog,
        logsCategory: "$logsCategory$_logsCategorySeparator$subCategory",
      );
}
