// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/src/loggers/helpers/logs_helper.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';
import 'package:act_logger_manager/src/mixins/mixin_logger_config.dart';
import 'package:act_logger_manager/src/services/logger_singleton.dart';
import 'package:act_logger_manager/src/types/safe_external_loggers.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Callback to register when you want to listen for platform errors
typedef ActLogsErrorCallback = void Function(Object exception, StackTrace stackTrace);

/// This class manages the [Logger] plugin class
abstract class LoggerManager extends AbsWithLifeCycle with MixinActLogger {
  /// This is the logger of the logger manager
  late final LogsHelper _logger;

  /// Handlers to manage flutter exceptions; those not already managed by try/catch
  final Set<FlutterExceptionHandler> _flutterExceptionHandler;

  /// Callback used to manager platform exceptions; those not managed by the flutter exceptions
  final Set<ActLogsErrorCallback> _platformErrorCallback;

  /// Used to get the logger configuration.
  final MixinLoggerConfig Function() _loggerConfigGetter;

  /// Get the logger configuration.
  @protected
  MixinLoggerConfig Function() get loggerConfigGetter => _loggerConfigGetter;

  /// Class constructor
  LoggerManager({
    required MixinLoggerConfig Function() loggerConfigGetter,
  })  : _loggerConfigGetter = loggerConfigGetter,
        _flutterExceptionHandler = {},
        _platformErrorCallback = {};

  /// Init the manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    final minLevel = _loggerConfigGetter().logLevelEnv.load();

    final instance = LoggerSingleton.createOrUpdateInstance(
      minLevel: minLevel,
    );

    await instance.externalLogger.initLifeCycle();

    _logger = LogsHelper.withExternalLogger(
      externalLogger: instance.externalLogger,
    );

    FlutterError.onError = _onFlutterError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to
    // third parties.
    PlatformDispatcher.instance.onError = _onPlatformError;

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
      _logger.log(
        message,
        level: level,
        error: error,
        stackTrace: stackTrace,
      );

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

  /// Add a handler to listen for Flutter exceptions
  void addFlutterExceptionHandler(FlutterExceptionHandler handler) {
    _flutterExceptionHandler.add(handler);
  }

  /// Remove the handler linked to the listen of Flutter exceptions
  void removeFlutterExceptionHandler(FlutterExceptionHandler handler) {
    _flutterExceptionHandler.remove(handler);
  }

  /// Add a callback to listen for platform errors
  void addPlatformErrorCallback(ActLogsErrorCallback callback) {
    _platformErrorCallback.add(callback);
  }

  /// Remove the callback which listen platform errors
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

  /// Called when a flutter error is thrown
  void _onFlutterError(FlutterErrorDetails details) {
    e(details.exceptionAsString(), details.exception, details.stack);
    for (final handler in _flutterExceptionHandler) {
      handler(details);
    }
  }

  /// Called when a platform error is thrown
  bool _onPlatformError(Object exception, StackTrace stackTrace) {
    e(exception, exception, stackTrace);
    for (final callback in _platformErrorCallback) {
      callback(exception, stackTrace);
    }
    return true;
  }

  /// Get the default logger of the app, which is always ready to be used, even before the manager
  /// initialization.
  static MixinActLogger getSafeLogger({
    LogsLevel defaultMinLevel = LogsLevel.warn,
  }) {
    final instance = LoggerSingleton.createInstance(
      externalLoggers: SafeExternalLoggers.toExternalLoggersMap(),
      minLevel: defaultMinLevel,
    );

    return LogsHelper.withExternalLogger(
      externalLogger: instance.externalLogger,
    );
  }

  /// To call in order to dispose the class elements
  @override
  Future<void> disposeLifeCycle() async {
    await LoggerSingleton.instanceOrNull?.externalLogger.disposeLifeCycle();

    await super.disposeLifeCycle();
  }
}
