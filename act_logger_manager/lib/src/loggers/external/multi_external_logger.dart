// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/src/types/logs_level.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';

/// This class is used to log messages to multiple external loggers at the same time.
class MultiExternalLogger with MixinWithLifeCycleDispose, MixinWithLifeCycle, MixinExternalLogger {
  /// The map of external loggers, with their key.
  final Map<Enum, MixinExternalLogger> _externalLoggers;

  /// This variable is used to know if the multi external logger has been initialized
  bool _isInitialized;

  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.getter}
  ///
  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.setter}
  @override
  LogsLevel minLevel;

  /// Class constructor
  MultiExternalLogger({
    this.minLevel = LogsLevel.all,
    Map<Enum, MixinExternalLogger>? externalLoggers,
  })  : _isInitialized = false,
        _externalLoggers = Map<Enum, MixinExternalLogger>.from(externalLoggers ?? {});

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    await Future.wait(_externalLoggers.entries.map((logger) => logger.value.initLifeCycle()));

    _isInitialized = true;
  }

  /// {@template act_logger_manager.MultiExternalLogger.addExternalLogger}
  /// This method is used to add an external logger to the multi external logger.
  ///
  /// If a logger with the same key already exists, it will be removed and disposed before adding
  /// the new logger.
  ///
  /// When adding a logger, the multi external logger takes the ownership of the logger, and will
  /// dispose it when it is removed or when the multi external logger is disposed.
  ///
  /// If the multi external logger is already initialized, the added logger will be initialized
  /// immediately.
  /// {@endtemplate}
  Future<void> addExternalLogger(Enum loggerKey, MixinExternalLogger externalLogger) async {
    await removeExternalLogger(loggerKey);

    if (_isInitialized) {
      await externalLogger.initLifeCycle();
    }

    _externalLoggers[loggerKey] = externalLogger;
  }

  /// {@template act_logger_manager.MultiExternalLogger.removeExternalLogger}
  /// This method is used to remove an external logger from the multi external logger.
  /// The removed logger will be disposed.
  /// {@endtemplate}
  Future<void> removeExternalLogger(Enum loggerKey) async {
    final existingLogger = _externalLoggers.remove(loggerKey);
    await existingLogger?.disposeLifeCycle();
  }

  /// {@template act_logger_manager.MultiExternalLogger.clearExternalLoggers}
  /// This method is used to remove all the external loggers from the multi external logger.
  /// All the removed loggers will be disposed.
  /// {@endtemplate}
  Future<void> clearExternalLoggers() async {
    await Future.wait(_externalLoggers.entries.map((logger) => logger.value.disposeLifeCycle()));
    _externalLoggers.clear();
  }

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
    if (!_testIfItWouldBeLogged(level)) {
      return;
    }

    for (final externalLogger in _externalLoggers.values) {
      externalLogger.log(
        message: message,
        level: level,
        error: error,
        stackTrace: stackTrace,
        categories: categories,
        time: time,
      );
    }
  }

  /// {@macro act_logger_manager.MixinExternalLogger.wouldBeLogged}
  @override
  bool wouldBeLogged({required LogsLevel level, List<String>? categories}) {
    if (!_testIfItWouldBeLogged(level)) {
      return false;
    }

    return _externalLoggers.entries.any((externalLogger) =>
        externalLogger.value.wouldBeLogged(level: level, categories: categories));
  }

  /// Test if a message with a given level would be logged by the multi external logger, without
  /// considering the sub external loggers.
  bool _testIfItWouldBeLogged(LogsLevel level) => level.index >= minLevel.index;

  /// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await clearExternalLoggers();

    return super.disposeLifeCycle();
  }
}
