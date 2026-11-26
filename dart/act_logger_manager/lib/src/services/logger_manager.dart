// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_life_cycle/act_dart_life_cycle.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/src/loggers/helpers/logs_helper.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';
import 'package:act_logger_manager/src/mixins/mixin_logger_config.dart';
import 'package:act_logger_manager/src/services/logger_singleton.dart';
import 'package:act_logger_manager/src/types/safe_external_loggers.dart';
import 'package:meta/meta.dart';

/// Callback to register when you want to listen for platform errors
typedef ActLogsErrorCallback = void Function(Object exception, StackTrace stackTrace);

/// This class manages the logging of the app.
abstract class LoggerManager extends AbsWithLifeCycle with MixinActLogger {
  /// This is the logger of the logger manager
  late final LogsHelper _logger;

  /// Callbacks called when an uncaught error is logged with [logUncaughtError]; those errors are
  /// not managed by try/catch
  final Set<ActLogsErrorCallback> _platformErrorCallback;

  /// Used to get the logger configuration.
  final MixinLoggerConfig Function() _loggerConfigGetter;

  /// Get the logger configuration.
  @protected
  MixinLoggerConfig Function() get loggerConfigGetter => _loggerConfigGetter;

  /// Class constructor
  LoggerManager({required this._loggerConfigGetter}) : _platformErrorCallback = {};

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    final minLevel = _loggerConfigGetter().logLevelEnv.load();

    final instance = LoggerSingleton.createOrUpdateInstance(minLevel: minLevel);

    await instance.externalLogger.initLifeCycle();

    _logger = LogsHelper.withExternalLogger(externalLogger: instance.externalLogger);

    final externalLoggers = await buildExternalLoggersToReplaceSafeLogger();
    if (externalLoggers.isNotEmpty) {
      await _replaceSafeLogger(externalLoggers: externalLoggers);
    }
  }

  /// {@template act_logger_manager.LoggerManager.buildExternalLoggersToReplaceSafeLogger}
  /// This method is used to build the external loggers that will replace the safe logger when the
  /// manager is initialized.
  ///
  /// By default, it returns an empty map, which means that the safe logger
  /// will not be replaced. You can override this method to return the external loggers that
  /// you want to use in your app, and that will replace the safe logger when the manager is initialized.
  /// {@endtemplate}
  @protected
  Future<Map<Enum, MixinExternalLogger>> buildExternalLoggersToReplaceSafeLogger() async => {};

  /// {@macro act_foundation.MixinActLogger.log}
  @override
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void log(dynamic message, {required LogsLevel level, dynamic error, StackTrace? stackTrace}) =>
      _logger.log(message, level: level, error: error, stackTrace: stackTrace);

  /// {@macro act_foundation.MixinActLogger.logMessages}
  ///
  /// The method uses the [LogsHelper.defaultLogLevel] to log the message.
  @override
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void logMessages(dynamic message) => _logger.logMessages(message);

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  @override
  MixinActLogger createAbsSubLogger({required String subCategory}) =>
      _logger.createAbsSubLogger(subCategory: subCategory);

  /// {@macro act_foundation.MixinActLogger.createAbsSubLogger}
  @override
  MixinActLogger createAbsSubLoggerMinLevel({required String subCategory, LogsLevel? minLevel}) =>
      _logger.createAbsSubLoggerMinLevel(subCategory: subCategory, minLevel: minLevel);

  /// {@macro act_foundation.MixinActLogger.wouldBeLogged}
  @override
  bool wouldBeLogged(LogsLevel level) => _logger.wouldBeLogged(level);

  /// Add a callback to listen for uncaught errors, given to [logUncaughtError]
  void addPlatformErrorCallback(ActLogsErrorCallback callback) {
    _platformErrorCallback.add(callback);
  }

  /// Remove the callback which listen uncaught errors
  void removePlatformErrorCallback(ActLogsErrorCallback callback) {
    _platformErrorCallback.remove(callback);
  }

  /// This method is used to add an external logger to the logger manager.
  ///
  /// If a logger with the same key already exists, it will be removed and disposed before adding
  /// the new logger.
  ///
  /// When adding a logger, the logger manager takes the ownership of the logger, and will
  /// dispose it when it is removed or when the logger manager is disposed.
  ///
  /// If the logger manager is already initialized, the added logger will be initialized
  /// immediately.
  Future<void> addExternalLogger(Enum loggerKey, MixinExternalLogger externalLogger) async =>
      LoggerSingleton.instance.externalLogger.addExternalLogger(loggerKey, externalLogger);

  /// This method is used to remove an external logger from the logger manager.
  /// The removed logger will be disposed.
  Future<void> removeExternalLogger(Enum loggerKey) async =>
      LoggerSingleton.instance.externalLogger.removeExternalLogger(loggerKey);

  /// Log an uncaught error and give it to the callbacks added with [addPlatformErrorCallback].
  ///
  /// This is the entry point of the errors which no `try`/`catch` handled: the error is logged at
  /// the error level, then each registered callback is called with it.
  ///
  /// The manager doesn't catch uncaught errors by itself: the caller has to wire this method to the
  /// source of those errors. In a Flutter application, `runActApp` of `act_global_manager` does it.
  /// A pure Dart host can call it where it catches the errors, for instance from the `onError`
  /// callback of `runZonedGuarded`.
  ///
  /// Always returns true, which tells the caller (for instance the `onError` callback of Flutter's
  /// `PlatformDispatcher`) that the error has been handled.
  bool logUncaughtError(Object exception, StackTrace stackTrace) {
    e(exception, exception, stackTrace);
    for (final callback in _platformErrorCallback) {
      callback(exception, stackTrace);
    }
    return true;
  }

  /// This method is used to replace the safe logger with the external loggers provided in the
  /// [externalLoggers] parameter. The safe logger is the logger that is used before the manager is
  /// initialized, and that is created with the [SafeExternalLoggers] enum.
  Future<void> _replaceSafeLogger({required Map<Enum, MixinExternalLogger> externalLoggers}) async {
    final externalLogger = LoggerSingleton.instance.externalLogger;

    for (final logger in externalLoggers.entries) {
      await externalLogger.addExternalLogger(logger.key, logger.value);
    }
    await externalLogger.removeExternalLogger(SafeExternalLoggers.console);
  }

  /// Get the default logger of the app, which is always ready to be used, even before the manager
  /// initialization.
  static MixinActLogger getSafeLogger({LogsLevel defaultMinLevel = LogsLevel.warn}) {
    final instance = LoggerSingleton.createInstance(
      externalLoggers: SafeExternalLoggers.toExternalLoggersMap(),
      minLevel: defaultMinLevel,
    );

    return LogsHelper.withExternalLogger(externalLogger: instance.externalLogger);
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await LoggerSingleton.instanceOrNull?.externalLogger.disposeLifeCycle();

    await super.disposeLifeCycle();
  }
}
