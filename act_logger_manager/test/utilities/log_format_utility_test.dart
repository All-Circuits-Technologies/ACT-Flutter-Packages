// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// The time every message which has one is logged at.
final _time = DateTime.utc(2025, 1, 8, 11, 50, 38, 470);

/// The same time, as it is written in the messages.
const _writtenTime = "2025-01-08T11:50:38.470Z";

void main() {
  group("LogFormatUtility.formatCategories", () {
    test("joins the categories with a separator", () {
      expect(LogFormatUtility.formatCategories(["default", "other"]), "default/other");
    });

    test("returns the category itself when there is only one", () {
      expect(LogFormatUtility.formatCategories(["default"]), "default");
    });

    test("returns an empty string when there is no category", () {
      expect(LogFormatUtility.formatCategories([]), isEmpty);
    });
  });

  group("LogFormatUtility.formatLogMessages", () {
    test("writes the time, the level and the categories before the message", () {
      final lines = LogFormatUtility.formatLogMessages(
        message: "Global manager initialized.",
        categories: ["default", "other"],
        level: LogsLevel.info,
        time: _time,
      );

      expect(lines, ["$_writtenTime-[info][default/other]: Global manager initialized."]);
    });

    test("writes the message alone when it has no context", () {
      expect(LogFormatUtility.formatLogMessages(message: "a message"), ["a message"]);
    });

    test("writes the time without a separator when it is the only context", () {
      expect(LogFormatUtility.formatLogMessages(message: "a message", time: _time), [
        "$_writtenTime: a message",
      ]);
    });

    test("writes the level alone when it is the only context", () {
      expect(
        LogFormatUtility.formatLogMessages(message: "a message", level: LogsLevel.warn),
        ["[warn]: a message"],
      );
    });

    test("writes the categories alone when they are the only context", () {
      expect(
        LogFormatUtility.formatLogMessages(message: "a message", categories: ["conf"]),
        ["[conf]: a message"],
      );
    });

    test("keeps the separator between the time and the level", () {
      expect(
        LogFormatUtility.formatLogMessages(
          message: "a message",
          level: LogsLevel.warn,
          time: _time,
        ),
        ["$_writtenTime-[warn]: a message"],
      );
    });

    test("keeps the separator between the time and the categories", () {
      expect(
        LogFormatUtility.formatLogMessages(
          message: "a message",
          categories: ["conf"],
          time: _time,
        ),
        ["$_writtenTime-[conf]: a message"],
      );
    });

    test("writes the time in the universal time zone", () {
      final lines = LogFormatUtility.formatLogMessages(
        message: "a message",
        time: _time.toLocal(),
      );

      expect(lines, ["$_writtenTime: a message"]);
    });

    test("writes the level in lower case", () {
      expect(
        LogFormatUtility.formatLogMessages(message: "a message", level: LogsLevel.error),
        ["[error]: a message"],
      );
    });

    test("writes the exception on its own line, with the same prefix", () {
      final lines = LogFormatUtility.formatLogMessages(
        message: "a message",
        exception: "an exception",
        level: LogsLevel.error,
      );

      expect(lines, ["[error]: a message", "[error]: an exception"]);
    });

    test("writes the stack trace on its own line, after the exception", () {
      final lines = LogFormatUtility.formatLogMessages(
        message: "a message",
        exception: "an exception",
        stackTrace: StackTrace.fromString("a stack trace"),
      );

      expect(lines, ["a message", "an exception", "a stack trace"]);
    });

    test("leaves out the message when there is none", () {
      final lines = LogFormatUtility.formatLogMessages(exception: "an exception");

      expect(lines, ["an exception"]);
    });

    test("returns no line when there is nothing to write", () {
      expect(LogFormatUtility.formatLogMessages(level: LogsLevel.info, time: _time), isEmpty);
    });

    test("writes a message which is not a string as it describes itself", () {
      expect(LogFormatUtility.formatLogMessages(message: 3), ["3"]);
      expect(LogFormatUtility.formatLogMessages(message: ["a", "b"]), ["[a, b]"]);
    });
  });
}
