// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/src/loggers/printers/default_log_printer.dart';
import 'package:act_logger_manager/src/mixins/mixin_csl_logger_config.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';
import 'package:act_logger_manager/src/models/filters/default_log_filter.dart';
import 'package:act_logger_manager/src/models/log_message.dart';
import 'package:act_logger_manager/src/types/ext_logs_level.dart';
import 'package:logger/logger.dart';

/// This class is an implementation of [MixinExternalLogger] that uses the Logger package to log
/// messages to the console.
class ConsoleExternalLogger
    with MixinWithLifeCycleDispose, MixinWithLifeCycle, MixinExternalLogger {
  /// The Logger instance used to log messages to the console.
  late final Logger _logger;

  /// The log filter used to filter the log messages based on their level.
  final DefaultLogFilter _logFilter;

  /// The log printer used to print the log messages in a specific format.
  final DefaultLogPrinter _logPrinter;

  /// The function used to get the config manager of the console logger, which is used to get the
  /// config variables of the console logger.
  ///
  /// If null, we don't use the getter.
  final MixinCslLoggerConfig Function()? _configGetter;

  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.getter}
  @override
  LogsLevel get minLevel => _logFilter.minLevel;

  /// {@macro act_logger_manager.MixinExternalLogger.minLevel.setter}
  @override
  set minLevel(LogsLevel value) => _logFilter.minLevel = value;

  /// {@macro act_logger_manager.DefaultLogFilter.printLogInRelease}
  bool get printLogInRelease => _logFilter.printLogInRelease;

  /// {@macro act_logger_manager.DefaultLogFilter.printLogInRelease}
  set printLogInRelease(bool value) => _logFilter.printLogInRelease = value;

  /// Factory constructor to create a ConsoleExternalLogger with a config getter.
  ///
  /// Because we get the log level from the config, we set the minimum log level to [LogsLevel.off]
  /// to avoid logging messages before getting the log level from the config.
  factory ConsoleExternalLogger.fromConfigGetter(
          {required MixinCslLoggerConfig Function() configGetter}) =>
      ConsoleExternalLogger._(configGetter: configGetter, minLevel: LogsLevel.off);

  /// Factory constructor to create a ConsoleExternalLogger with a minimum log level.
  factory ConsoleExternalLogger.withMinLevel({LogsLevel minLevel = LogsLevel.all}) =>
      ConsoleExternalLogger._(
        minLevel: minLevel,
        configGetter: null,
      );

  /// Class constructor
  ConsoleExternalLogger._(
      {required LogsLevel minLevel, required MixinCslLoggerConfig Function()? configGetter})
      : _logFilter = DefaultLogFilter(minLevel: minLevel),
        _logPrinter = DefaultLogPrinter(),
        _configGetter = configGetter {
    _logger = Logger(
      filter: _logFilter,
      printer: _logPrinter,
      output: ConsoleOutput(),
    );
  }

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    final configManager = _configGetter?.call();
    if (configManager != null) {
      final logLevel = configManager.cslLogLevelEnv.load();
      minLevel = logLevel;
      printLogInRelease = configManager.logPrintInReleaseEnv.load();
    }
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
    _logger.log(
        level.toLoggerLevel, LogMessage(message: message, categories: categories ?? const []),
        error: error, stackTrace: stackTrace, time: time);
  }

  /// {@macro act_logger_manager.MixinExternalLogger.wouldBeLogged}
  @override
  bool wouldBeLogged({required LogsLevel level, List<String>? categories}) =>
      _logFilter.shouldLog(LogEvent(level.toLoggerLevel, null));

  /// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _logger.close();

    return super.disposeLifeCycle();
  }
}
