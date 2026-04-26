// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_firebase_crash/src/models/firebase_crash_debug_config.dart';
import 'package:act_foundation/src/types/logs_level.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// This is the external logger used to log messages to firebase crashlytics.
class CrashlyticsExternalLogger
    with MixinWithLifeCycleDispose, MixinWithLifeCycle, MixinExternalLogger {
  /// The crash debug config used to get the log level and other config variables for the crash
  /// debug feature.
  final FirebaseCrashDebugConfig crashDebugConfig;

  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.getter}
  @override
  LogsLevel get minLevel => crashDebugConfig.level;

  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.setter}
  @override
  set minLevel(LogsLevel value) {
    // We don't set the log level of the crash debug config because it's not a mutable config, so we
    // can't change it at runtime. If we want to change the log level at runtime, we need to create
    // a new crash debug config with the new log level and set it to the logger.
  }

  /// Class constructor
  const CrashlyticsExternalLogger({
    required this.crashDebugConfig,
  });

  /// {@macro act_logger_manager.MixinExternalLogger.log}
  @override
  void log(
      // We don't know the type of the objects we pass to the log messages
      // ignore: avoid_annotating_with_dynamic
      {required dynamic message,
      required LogsLevel level,
      // We don't know the type of the objects we pass to the log messages
      // ignore: avoid_annotating_with_dynamic
      dynamic error,
      StackTrace? stackTrace,
      List<String>? categories,
      DateTime? time}) {
    if (!_testIfLogWouldBeLogged(level: level)) {
      return;
    }

    final logsMessage = LogFormatUtility.formatLogMessages(
      message: message,
      exception: error,
      stackTrace: stackTrace,
      categories: categories ?? const [],
      time: time,
    );

    unawaited(_logMessagesToCrashlytics(logMessages: logsMessage));
  }

  /// {@macro act_logger_manager.MixinExternalLogger.wouldBeLogged}
  @override
  bool wouldBeLogged({required LogsLevel level, List<String>? categories}) =>
      _testIfLogWouldBeLogged(level: level);

  /// This method is used to test if a log with a given level would be logged by the logger, based on the
  /// log level of the crash debug config.
  bool _testIfLogWouldBeLogged({required LogsLevel level}) => level.index >= minLevel.index;

  /// This method is used to log messages to firebase crashlytics.
  Future<void> _logMessagesToCrashlytics({
    required List<String> logMessages,
  }) async {
    final crashlytics = FirebaseCrashlytics.instance;
    for (final logMessage in logMessages) {
      await crashlytics.log(logMessage);
    }
  }
}
