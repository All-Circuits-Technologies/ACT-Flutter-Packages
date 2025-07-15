// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/src/mixins/mixin_logger_config.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Callback to register when you want to listen for platform errors
typedef ActLogsErrorCallback = void Function(Object exception, StackTrace stackTrace);

/// Builder for creating the LoggerManager
class LoggerBuilder<C extends MixinLoggerConfig> extends AbsManagerBuilder<LoggerManager> {
  /// A factory to create a manager instance
  const LoggerBuilder() : super(_LoggerManagerPriv<C>.new);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [C];
}

/// This class is used to create a Logger Manager with the right ConfigManager type
///
/// This class is private and only used in the package.
class _LoggerManagerPriv<C extends MixinLoggerConfig> extends LoggerManager {
  /// Get the config manager linked to the logger manager
  @override
  MixinLoggerConfig getLoggerConfig() => globalGetIt().get<C>();
}

/// This class manages the [Logger] plugin class
abstract class LoggerManager extends AbsWithLifeCycle {
  /// This is the current logger used by the application
  late final Logger _logger;

  /// Handlers to manage flutter exceptions; those not already managed by try/catch
  final Set<FlutterExceptionHandler> _flutterExceptionHandler;

  /// Callback used to manager platform exceptions; those not managed by the flutter exceptions
  final Set<ActLogsErrorCallback> _platformErrorCallback;

  /// Constructor
  LoggerManager()
      : _flutterExceptionHandler = {},
        _platformErrorCallback = {};

  /// Get the config manager linked to the logger manager
  @protected
  MixinLoggerConfig getLoggerConfig();

  /// Init the manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    final confManager = getLoggerConfig();

    _logger = Logger(
      level: confManager.logLevelEnv.load(),
      filter: AppLogFilter(printLogInRelease: confManager.logPrintInReleaseEnv.load()),
      printer: AppLogPrinter(),
    );

    _logger.d("Application start");

    FlutterError.onError = _onFlutterError;

    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to
    // third parties.
    PlatformDispatcher.instance.onError = _onPlatformError;
  }

  /// Called when a flutter error is thrown
  void _onFlutterError(FlutterErrorDetails details) {
    e(details.exceptionAsString(), null, details.exception, details.stack);
    for (final handler in _flutterExceptionHandler) {
      handler(details);
    }
  }

  /// Called when a platform error is thrown
  bool _onPlatformError(Object exception, StackTrace stackTrace) {
    e(exception, null, exception, stackTrace);
    for (final callback in _platformErrorCallback) {
      callback(exception, stackTrace);
    }
    return true;
  }

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

  /// Register an [OutputCallback] which is called for each new [OutputEvent].
  void addOutputListener(OutputCallback callback) => Logger.addOutputListener(callback);

  /// Removes a [OutputCallback] which was previously registered.
  ///
  /// Returns whether the callback was successfully removed.
  void removeOutputListener(OutputCallback callback) => Logger.removeOutputListener(callback);

  /// Register a [LogCallback] which is called for each new [LogEvent].
  void addLogListener(LogCallback callback) => Logger.addLogListener(callback);

  /// Removes a [LogCallback] which was previously registered.
  ///
  /// Returns whether the callback was successfully removed.
  bool removeLogListener(LogCallback callback) => Logger.removeLogListener(callback);

  /// Log a message at level [Level.trace].
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void t(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.t(
        _MessageObject(
          category: category,
          message: message,
        ),
        error: error,
        stackTrace: stackTrace,
      );

  /// Log a message at level [Level.debug].
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void d(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.d(
        _MessageObject(
          category: category,
          message: message,
        ),
        error: error,
        stackTrace: stackTrace,
      );

  /// Log a message at level [Level.info].
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void i(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.i(
        _MessageObject(
          category: category,
          message: message,
        ),
        error: error,
        stackTrace: stackTrace,
      );

  /// Log a message at level [Level.warning].
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void w(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.w(
        _MessageObject(
          category: category,
          message: message,
        ),
        error: error,
        stackTrace: stackTrace,
      );

  /// Log a message at level [Level.error].
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void e(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.e(
        _MessageObject(
          category: category,
          message: message,
        ),
        error: error,
        stackTrace: stackTrace,
      );

  /// Log a message at level [Level.fatal].
  // We don't know the type of the objects we pass to the log messages
  // ignore: avoid_annotating_with_dynamic
  void f(dynamic message, [String? category, dynamic error, StackTrace? stackTrace]) => _logger.f(
        _MessageObject(
          category: category,
          message: message,
        ),
        error: error,
        stackTrace: stackTrace,
      );

  /// Log a message with [level].
  void log(
    Level level,
    // We don't know the type of the objects we pass to the log messages
    // ignore: avoid_annotating_with_dynamic
    dynamic message, [
    String? category,
    // We don't know the type of the objects we pass to the log messages
    // ignore: avoid_annotating_with_dynamic
    dynamic error,
    StackTrace? stackTrace,
  ]) =>
      _logger.log(
        level,
        _MessageObject(
          category: category,
          message: message,
        ),
        error: error,
        stackTrace: stackTrace,
      );

  /// To call in order to dispose the class elements
  @override
  Future<void> disposeLifeCycle() async {
    await _logger.close();
    await super.disposeLifeCycle();
  }
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
  /// The method called to transform a [LogEvent] object to printable logs
  @override
  List<String> log(LogEvent event) => [defaultFormatLogEvent(event)];

  /// This method formats the log event with the default format used in all the ACT apps
  static String defaultFormatLogEvent(LogEvent event) =>
      "${DateTime.now().toIso8601String()}-[${event.level.str}]: ${event.message}";
}
