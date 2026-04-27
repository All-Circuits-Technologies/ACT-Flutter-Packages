// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';

/// This mixin describes an external logger, which is a logger that is not created by the library
/// but is passed to the library by the user.
mixin MixinExternalLogger on MixinWithLifeCycle {
  /// {@template act_logger_manager.MixinExternalLogger.minLevel.getter}
  /// The minimum level of logs that the external logger will log. Logs with a level lower than this
  /// will be ignored.
  /// {@endtemplate}
  LogsLevel get minLevel;

  /// {@template act_logger_manager.MixinExternalLogger.minLevel.setter}
  /// Set the minimum level of logs that the external logger will log. Logs with a level lower than
  /// this will be ignored.
  /// {@endtemplate}
  set minLevel(LogsLevel value);

  /// {@template act_logger_manager.MixinExternalLogger.log}
  /// This method is used to log message to an external logger.
  /// {@endtemplate}
  void log({
    // We don't know the type of the objects we pass to the log messages
    // ignore: avoid_annotating_with_dynamic
    required dynamic message,
    required LogsLevel level,
    // We don't know the type of the objects we pass to the log messages
    // ignore: avoid_annotating_with_dynamic
    dynamic error,
    StackTrace? stackTrace,
    List<String>? categories,
    DateTime? time,
  });

  /// {@template act_logger_manager.MixinExternalLogger.wouldBeLogged}
  /// This method is used to know if a message with a given level and categories would be logged by
  /// the external logger.
  /// {@endtemplate}
  bool wouldBeLogged({
    required LogsLevel level,
    List<String>? categories,
  });
}
