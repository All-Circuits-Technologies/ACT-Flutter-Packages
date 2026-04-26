// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';
import 'package:act_logger_manager/src/services/logger_singleton.dart';

/// Helpful class to manage logs with library and managers
class LogsHelper with MixinActLogger {
  /// This is the list of categories for this logger.
  ///
  /// It can be used to filter logs by categories or to add more context to the logs.
  ///
  /// The first category is the main category of the logger and the last one is the most specific.
  final List<String> categories;

  /// The log level is used with [logMessages] method, when we don't know the message log level.
  final LogsLevel defaultLogLevel;

  /// This is the minimum level to log messages.
  ///
  /// If the level of the message is lower than this level, the message will be skipped. If null,
  /// all messages will be logged (the _logger will decide if it logs the message or not).
  final LogsLevel? minLevel;

  /// This is the external logger used to log messages.
  final MixinExternalLogger externalLogger;

  /// Class constructor with external logger from singleton
  factory LogsHelper({
    String? category,
    LogsLevel? minLevel,
    LogsLevel defaultLogLevel = LogsLevel.debug,
  }) =>
      LogsHelper.withExternalLogger(
        externalLogger: LoggerSingleton.instance.externalLogger,
        category: category,
        minLevel: minLevel,
        defaultLogLevel: defaultLogLevel,
      );

  /// Class constructor with external logger
  LogsHelper.withExternalLogger({
    required this.externalLogger,
    String? category,
    this.minLevel,
    this.defaultLogLevel = LogsLevel.debug,
  }) : categories = [if (category != null) category];

  /// This constructor is used to create a sub logger from a parent logger.
  LogsHelper.createSubLogger({
    required LogsHelper parentLogger,
    String? subCategory,
    LogsLevel? minLevel,
    LogsLevel? defaultLogLevel,
  })  : externalLogger = parentLogger.externalLogger,
        categories = [
          ...parentLogger.categories,
          if (subCategory != null) subCategory,
        ],
        minLevel = minLevel ?? parentLogger.minLevel,
        defaultLogLevel = defaultLogLevel ?? parentLogger.defaultLogLevel;

  /// {@macro act_foundation.MixinActLogger.log}
  @override
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void log(dynamic message, {required LogsLevel level, dynamic error, StackTrace? stackTrace}) {
    if (!_testIfItWouldBeLogged(levelToTest: level)) {
      // We don't log the message if the level is lower than the minimum level
      return;
    }

    externalLogger.log(
        message: message,
        level: level,
        error: error,
        stackTrace: stackTrace,
        categories: categories,
        time: DateTime.now());
  }

  /// {@macro act_foundation.MixinActLogger.logMessages}
  ///
  /// The method uses the [defaultLogLevel] to log the message.
  @override
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void logMessages(dynamic message) => log(message, level: defaultLogLevel);

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  @override
  MixinActLogger createAbsSubLogger({required String subCategory}) => createSubLogger(
        subCategory: subCategory,
      );

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  @override
  MixinActLogger createAbsSubLoggerMinLevel({required String subCategory, LogsLevel? minLevel}) =>
      createSubLoggerMinLevel(
        subCategory: subCategory,
        minLevel: minLevel,
      );

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  LogsHelper createSubLogger({required String subCategory}) => LogsHelper.createSubLogger(
        parentLogger: this,
        subCategory: subCategory,
      );

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  LogsHelper createSubLoggerMinLevel({required String subCategory, LogsLevel? minLevel}) =>
      LogsHelper.createSubLogger(
        parentLogger: this,
        subCategory: subCategory,
        minLevel: minLevel,
      );

  /// {@macro act_foundation.MixinActLogger.wouldBeLogged}
  @override
  bool wouldBeLogged(LogsLevel level) {
    if (!_testIfItWouldBeLogged(levelToTest: level)) {
      // We don't go further if the level is lower than the minimum level
      return false;
    }

    return externalLogger.wouldBeLogged(
      level: level,
      categories: categories,
    );
  }

  /// Test if a message with a given [levelToTest] would be logged by the logger helper, without
  /// taking into  account the external logger's log level.
  bool _testIfItWouldBeLogged({required LogsLevel levelToTest}) =>
      minLevel == null || levelToTest.index >= minLevel!.index;
}
