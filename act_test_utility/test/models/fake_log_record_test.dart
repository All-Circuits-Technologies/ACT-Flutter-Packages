// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("FakeLogRecord equality", () {
    test("considers two records with the same values as equal", () {
      const record = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.info,
        message: "a message",
      );
      const otherRecord = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.info,
        message: "a message",
      );

      expect(record, otherRecord);
    });

    test("gives the same hash code to two records with the same values", () {
      const record = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.info,
        message: "a message",
      );
      const otherRecord = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.info,
        message: "a message",
      );

      expect(record.hashCode, otherRecord.hashCode);
    });

    test("considers two records with different categories as different", () {
      const record = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.info,
        message: "a message",
      );
      const otherRecord = FakeLogRecord(
        categories: ["main", "sub"],
        level: LogsLevel.info,
        message: "a message",
      );

      expect(record, isNot(otherRecord));
    });

    test("considers two records with different levels as different", () {
      const record = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.info,
        message: "a message",
      );
      const otherRecord = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.warn,
        message: "a message",
      );

      expect(record, isNot(otherRecord));
    });

    test("considers two records with different messages as different", () {
      const record = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.info,
        message: "a message",
      );
      const otherRecord = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.info,
        message: "another message",
      );

      expect(record, isNot(otherRecord));
    });

    test("considers two records with different errors as different", () {
      const error = FormatException("boom");
      const record = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.error,
        message: "a message",
        error: error,
      );
      const otherRecord = FakeLogRecord(
        categories: ["main"],
        level: LogsLevel.error,
        message: "a message",
      );

      expect(record, isNot(otherRecord));
    });
  });

  group("FakeLogRecord.toString", () {
    test("describes the level, the categories, the message and the error", () {
      const record = FakeLogRecord(
        categories: ["main", "sub"],
        level: LogsLevel.warn,
        message: "a message",
      );

      expect(
        record.toString(),
        "FakeLogRecord(level: LogsLevel.warn, categories: [main, sub], message: a message, "
        "error: null)",
      );
    });
  });
}
