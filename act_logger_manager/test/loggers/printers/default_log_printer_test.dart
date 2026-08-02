// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/src/loggers/printers/default_log_printer.dart';
import 'package:act_logger_manager/src/models/log_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

/// The time every event is logged at.
final _time = DateTime.utc(2025, 1, 8, 11, 50, 38, 470);

/// The same time, as it is written in the messages.
const _writtenTime = "2025-01-08T11:50:38.470Z";

void main() {
  group("DefaultLogPrinter.log", () {
    test("writes the categories of a message which carries some", () {
      final lines = DefaultLogPrinter().log(
        LogEvent(
          Level.info,
          const LogMessage(message: "a message", categories: ["default", "other"]),
          time: _time,
        ),
      );

      expect(lines, ["$_writtenTime-[info][default/other]: a message"]);
    });

    test("writes a message which carries no category", () {
      final lines = DefaultLogPrinter().log(
        LogEvent(Level.warning, const LogMessage(message: "a message", categories: []), time: _time),
      );

      expect(lines, ["$_writtenTime-[warn]: a message"]);
    });

    test("writes a message which the package didn't wrap", () {
      final lines = DefaultLogPrinter().log(LogEvent(Level.warning, "a message", time: _time));

      expect(lines, ["$_writtenTime-[warn]: a message"]);
    });

    test("writes the error and the stack trace of the event", () {
      final lines = DefaultLogPrinter().log(
        LogEvent(
          Level.error,
          const LogMessage(message: "a message", categories: []),
          time: _time,
          error: "an error",
          stackTrace: StackTrace.fromString("a stack trace"),
        ),
      );

      expect(lines, [
        "$_writtenTime-[error]: a message",
        "$_writtenTime-[error]: an error",
        "$_writtenTime-[error]: a stack trace",
      ]);
    });
  });
}
