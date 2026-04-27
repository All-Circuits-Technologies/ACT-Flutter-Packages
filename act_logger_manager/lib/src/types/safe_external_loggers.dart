// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/src/loggers/external/console_external_logger.dart';
import 'package:act_logger_manager/src/mixins/mixin_external_logger.dart';

/// This enum represents the default external loggers that can be used before all the loggers are
/// initialized.
enum SafeExternalLoggers {
  /// The console logger, which logs messages to the console.
  console(ConsoleExternalLogger.withMinLevel);

  /// The function used to create the external logger instance.
  final MixinExternalLogger Function() loggerFactory;

  /// Class constructor
  const SafeExternalLoggers(this.loggerFactory);

  /// This method is used to convert the enum values to a map of external loggers, where the key is
  /// the enum value and the value is the external logger instance created by the [loggerFactory]
  /// function.
  static Map<Enum, MixinExternalLogger> toExternalLoggersMap() =>
      Map<Enum, MixinExternalLogger>.fromEntries(
          SafeExternalLoggers.values.map((logger) => MapEntry(logger, logger.loggerFactory())));
}
