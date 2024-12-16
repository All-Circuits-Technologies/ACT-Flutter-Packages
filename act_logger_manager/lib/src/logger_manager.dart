// Copyright (c) 2020. BMS Circuits

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:logger/logger.dart';

/// Builder for creating the LoggerManager
class LoggerBuilder extends ManagerBuilder<LoggerManager> {
  /// A factory to create a manager instance
  LoggerBuilder({
    Level defaultLevel = Level.verbose,
  }) : super(() => LoggerManager(
              defaultLevel: defaultLevel,
            ));

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [];
}

/// This class manages the [Logger] plugin class
class LoggerManager extends AbstractManager {
  Logger _logger;

  /// Constructor
  ///
  /// The [defaultLevel] given allows to customize the level of logs to display
  LoggerManager({
    Level defaultLevel = Level.verbose,
  }) {
    _init(defaultLevel);
  }

  /// Init the manager
  @override
  Future<void> initManager() => null;

  /// To call in order to dispose the class elements
  @override
  Future<void> dispose() async {
    logger.close();

    return null;
  }

  /// This method is called to initialize the logger
  void _init(Level defaultLevel) {
    _logger = Logger(
      level: defaultLevel,
      filter: AppLogFilter(
        printLogInRelease: false,
      ),
      printer: AppLogPrinter(),
    );
    _logger.d("Application start");
  }

  /// Returns the default logger
  Logger get logger => _logger;
}

/// Extension of the log level
extension LevelExt on Level {
  /// Getter allows to get a string representation of the enum
  ///
  /// Good to know : the toString() method of enum will display the enum class
  /// name like this: Level.debug
  String get str => this.toString().split('.').last;
}

/// Application specific log filter
class AppLogFilter extends LogFilter {
  final bool printLogInRelease;
  static const bool isRelease = foundation.kReleaseMode;

  AppLogFilter({
    this.printLogInRelease = false,
  }) : super();

  @override
  bool shouldLog(LogEvent event) {
    return ((!isRelease || printLogInRelease) &&
        event.level.index >= this.level.index);
  }
}

/// Application specific log print
class AppLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    return [
      "${DateTime.now().toIso8601String()}-[${event.level.str}]: ${event.message}"
    ];
  }
}
