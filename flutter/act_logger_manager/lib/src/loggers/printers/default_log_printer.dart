// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/src/models/log_message.dart';
import 'package:act_logger_manager/src/types/ext_logs_level.dart';
import 'package:act_logger_manager/src/utilities/log_format_utility.dart';
import 'package:logger/logger.dart';

/// This class is a default log printer used with the Logger package.
///
/// It is used to print the log messages in a specific format.
class DefaultLogPrinter extends LogPrinter {
  /// Transform the [event] into a list of printable strings.
  @override
  List<String> log(LogEvent event) {
    var messageContent = event.message;
    final categories = <String>[];
    if (messageContent is LogMessage) {
      categories.addAll(messageContent.categories);
      messageContent = messageContent.message;
    }

    return LogFormatUtility.formatLogMessages(
      message: messageContent,
      exception: event.error,
      stackTrace: event.stackTrace,
      categories: categories,
      level: ExtLogsLevel.fromLoggerLevel(event.level),
      time: event.time,
    );
  }
}
