// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/src/loggers/external/console_external_logger.dart';
import 'package:act_logger_manager/src/mixins/mixin_default_logger_config.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';
import 'package:act_logger_manager/src/services/logger_manager.dart';
import 'package:act_logger_manager/src/types/default_external_loggers.dart';

/// Builder for creating the LoggerManager
///
/// We advise you to create the [LoggerManager] as soon as possible in your app, to be able to log
/// as many messages as possible.
/// [LoggerManager] may be depend on other managers
class DefaultLoggerBuilder<C extends MixinDefaultLoggerConfig>
    extends AbsLifeCycleFactory<LoggerManager> {
  /// A factory to create a manager instance
  DefaultLoggerBuilder({
    required MixinDefaultLoggerConfig Function() loggerConfigGetter,
  }) : super(() => DefaultLoggerManager(loggerConfigGetter: loggerConfigGetter));

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [C];
}

/// This class is the default implementation of the [LoggerManager] that can be used in the ACT
/// ecosystem.
///
/// It uses the [ConsoleExternalLogger] as the default external logger.
///
/// But you can override the [buildExternalLoggersToReplaceSafeLogger] method to replace the default
/// external loggers with your own external loggers. Or create a dedicated implementation of the
/// [LoggerManager] if you want to have more control over the loggers
class DefaultLoggerManager extends LoggerManager {
  /// Class constructor
  DefaultLoggerManager({
    required MixinDefaultLoggerConfig Function() loggerConfigGetter,
  }) : super(loggerConfigGetter: loggerConfigGetter);

  /// {@macro act_logger_manager.LoggerManager.buildExternalLoggersToReplaceSafeLogger}
  @override
  Future<Map<Enum, MixinExternalLogger>> buildExternalLoggersToReplaceSafeLogger() async => {
        DefaultExternalLoggers.console:
            ConsoleExternalLogger.fromConfigGetter(configGetter: _loggerDefaultConfig),
      };

  /// Get the logger configuration with the correct type.
  MixinDefaultLoggerConfig _loggerDefaultConfig() =>
      loggerConfigGetter() as MixinDefaultLoggerConfig;
}
