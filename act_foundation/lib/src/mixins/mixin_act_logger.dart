// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/src/types/logs_level.dart';

/// {@template act_foundation.IntfActLogger}
/// Interface for the logger used in the ACT packages.
/// This interface is used to log messages from the ACT packages, and to create sub loggers with
/// different categories and log levels.
/// {@endtemplate}
mixin MixinActLogger {
  /// {@template act_foundation.MixinActLogger.log}
  /// Log a message at the given [level].
  /// {@endtemplate}
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void log(dynamic message, {required LogsLevel level, dynamic error, StackTrace? stackTrace});

  /// {@template act_foundation.MixinActLogger.t}
  /// Log a message at level [LogsLevel.trace]
  /// {@endtemplate}
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void t(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      log(message, level: LogsLevel.trace, error: error, stackTrace: stackTrace);

  /// {@template act_foundation.MixinActLogger.d}
  /// Log a message at level [LogsLevel.debug]
  /// {@endtemplate}
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void d(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      log(message, level: LogsLevel.debug, error: error, stackTrace: stackTrace);

  /// {@template act_foundation.MixinActLogger.i}
  /// Log a message at level [LogsLevel.info]
  /// {@endtemplate}
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void i(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      log(message, level: LogsLevel.info, error: error, stackTrace: stackTrace);

  /// {@template act_foundation.MixinActLogger.w}
  /// Log a message at level [LogsLevel.warn]
  /// {@endtemplate}
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      log(message, level: LogsLevel.warn, error: error, stackTrace: stackTrace);

  /// {@template act_foundation.MixinActLogger.e}
  /// Log a message at level [LogsLevel.error]
  /// {@endtemplate}
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      log(message, level: LogsLevel.error, error: error, stackTrace: stackTrace);

  /// {@template act_foundation.MixinActLogger.f}
  /// Log a message at level [LogsLevel.fatal]
  /// {@endtemplate}
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void f(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      log(message, level: LogsLevel.fatal, error: error, stackTrace: stackTrace);

  /// {@template act_foundation.MixinActLogger.logMessages}
  /// Useful to log message from external libraries without any information about the log level to
  /// use. The log level is determined by the implementer of the interface.
  /// {@endtemplate}
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void logMessages(dynamic message);

  /// {@template act_foundation.MixinActLogger.createAbsSubLogger}
  /// This methods allowes to create a logs helper with a sub category: it has the same category,
  /// with an extra sub category.
  /// This call can be chained.
  /// {@endtemplate}
  MixinActLogger createAbsSubLogger({required String subCategory});

  /// {@template act_foundation.MixinActLogger.createAbsSubLogger}
  /// This methods allowes to create a logs helper with a sub category: it has the same category,
  /// with an extra sub category.
  /// This call can be chained.
  ///
  /// If [minLevel] is provided, the created logger will only log messages with a level higher or equal to
  /// [minLevel]. If not provided, the created logger will use the parent logger's log level.
  /// {@endtemplate}
  MixinActLogger createAbsSubLoggerMinLevel({required String subCategory, LogsLevel? minLevel});

  /// {@template act_foundation.MixinActLogger.wouldBeLogged}
  /// This method allows to know if a message with a given level would be logged by the logger.
  /// This is useful to avoid doing expensive operations to generate the log message if it won't be logged.
  /// {@endtemplate}
  bool wouldBeLogged(LogsLevel level);
}
