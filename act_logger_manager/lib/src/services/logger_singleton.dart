// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/src/loggers/external/multi_external_logger.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';

/// This singleton is used to store the main external logger used to log the messages.
class LoggerSingleton {
  /// The instance of this singleton
  static LoggerSingleton? _instance;

  /// Getter to this instance
  ///
  /// This class has to be created by calling [createInstance] before calling this getter
  static LoggerSingleton get instance {
    if (_instance == null) {
      throw ActSingletonNotCreatedError<LoggerSingleton>();
    }

    return _instance!;
  }

  /// Getter to this instance, but it can be null if the singleton is not created yet.
  static LoggerSingleton? get instanceOrNull => _instance;

  /// The external logger used to log the messages.
  final MultiExternalLogger externalLogger;

  /// Create the singleton instance.
  ///
  /// This method has to be called only once or an exception will be raised.
  static LoggerSingleton createInstance(
      {LogsLevel minLevel = LogsLevel.all, Map<Enum, MixinExternalLogger>? externalLoggers}) {
    if (_instance != null) {
      // The singleton instance already exists, we do nothing more and return the existing instance
      return _instance!;
    }

    _instance = LoggerSingleton._(MultiExternalLogger(
        externalLoggers: Map<Enum, MixinExternalLogger>.from(externalLoggers ?? {}),
        minLevel: minLevel));
    return _instance!;
  }

  /// Create the singleton instance if it doesn't exist, or update the log level of the existing
  /// instance if it already exists.
  static LoggerSingleton createOrUpdateInstance({required LogsLevel minLevel}) {
    if (_instance == null) {
      return createInstance(minLevel: minLevel);
    }

    _instance!.externalLogger.minLevel = minLevel;
    return _instance!;
  }

  /// Private class constructor
  LoggerSingleton._(this.externalLogger);
}
