// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/src/models/logger_init_config.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:logger/logger.dart';

/// Builder for creating the LoggerManager
class LoggerBuilder extends ManagerBuilder<LoggerManager> {
  /// A factory to create a manager instance
  LoggerBuilder({
    LoggerInitConfig defaultInitConfig = const LoggerInitConfig(
      logLevel: foundation.kReleaseMode ? Level.warning : Level.verbose,
    ),
  }) : super(() => LoggerManager(defaultInitConfig: defaultInitConfig));

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [];
}

/// This class manages the [Logger] plugin class
class LoggerManager extends AbstractManager {
  /// This is the current logger used by the application
  late Logger _logger;

  /// The init config used for the current logger
  LoggerInitConfig _currentInitConfig;

  /// True if [_logger] has been initialized at least once
  bool _initialized;

  /// The current init config
  LoggerInitConfig get currentInitConfig => _currentInitConfig;

  /// Constructor
  ///
  /// The [logLevel] given allows to customize the level of logs to display
  LoggerManager({
    required LoggerInitConfig defaultInitConfig,
  })  : _initialized = false,
        _currentInitConfig = defaultInitConfig;

  /// Init the manager
  @override
  Future<void> initManager() async {
    await reInitLogger(initConfig: _currentInitConfig);
    _initialized = true;
    _logger.d("Application start");
  }

  /// Allows to reinitialize the logger with different [initConfig]
  Future<void> reInitLogger({
    required LoggerInitConfig initConfig,
  }) async {
    Logger? previousLog;

    if (_initialized) {
      previousLog = _logger;
    }

    _logger = Logger(
      level: initConfig.logLevel,
      filter: AppLogFilter(printLogInRelease: initConfig.printLogInRelease),
      printer: AppLogPrinter(),
    );

    _currentInitConfig = initConfig;

    // We close the log after having create a new one, to avoid to loose logs in the process
    previousLog?.close();

    if (_initialized) {
      i("The logger has been reinitialized");
    }
  }

  /// To call in order to dispose the class elements
  @override
  Future<void> dispose() async {
    _logger.close();
    await super.dispose();
  }

  /// Log a message at level [Level.verbose].
  void v(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.v(
        _MessageObject(
          category: category,
          message: message,
        ),
        error,
        stackTrace,
      );

  /// Log a message at level [Level.debug].
  void d(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.d(
        _MessageObject(
          category: category,
          message: message,
        ),
        error,
        stackTrace,
      );

  /// Log a message at level [Level.info].
  void i(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.i(
        _MessageObject(
          category: category,
          message: message,
        ),
        error,
        stackTrace,
      );

  /// Log a message at level [Level.warning].
  void w(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.w(
        _MessageObject(
          category: category,
          message: message,
        ),
        error,
        stackTrace,
      );

  /// Log a message at level [Level.error].
  void e(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.e(
        _MessageObject(
          category: category,
          message: message,
        ),
        error,
        stackTrace,
      );

  /// Log a message at level [Level.wtf].
  void wtf(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) =>
      _logger.wtf(
        _MessageObject(
          category: category,
          message: message,
        ),
        error,
        stackTrace,
      );

  /// Log a message with [level].
  void log(Level level, dynamic message,
          [String? category, dynamic error, StackTrace? stackTrace]) =>
      _logger.log(
        level,
        _MessageObject(
          category: category,
          message: message,
        ),
        error,
        stackTrace,
      );
}

/// Extension of the log level
extension LevelExt on Level {
  /// Getter allows to get a string representation of the enum
  ///
  /// Good to know : the toString() method of enum will display the enum class
  /// name like this: Level.debug
  String get str => toString().split('.').last;
}

/// Application specific log filter
class AppLogFilter extends LogFilter {
  /// True to print the app log in the logcat in release
  final bool printLogInRelease;

  /// True if the application has been built in release mode
  static const bool isRelease = foundation.kReleaseMode;

  /// Class constructor
  AppLogFilter({
    this.printLogInRelease = false,
  }) : super();

  @override
  bool shouldLog(LogEvent event) =>
      ((!isRelease || printLogInRelease) && event.level.index >= level!.index);
}

/// Useful object to categorize the logs
class _MessageObject {
  /// The category of the message log
  final String? category;

  /// The message of the log
  final dynamic message;

  /// Class constructor
  _MessageObject({required this.category, required this.message});

  /// Override the [toString] method to display the category in message if it's defined
  @override
  String toString() {
    if (category == null) {
      return message.toString();
    }

    return "[$category] $message";
  }
}

/// Application specific log print
class AppLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) => [
        "${DateTime.now().toIso8601String()}-[${event.level.str}]: ${event.message}",
      ];
}
