// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/act_foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("LogsLevel", () {
    test("orders the levels from the most verbose to the least verbose", () {
      expect(LogsLevel.values, [
        LogsLevel.all,
        LogsLevel.trace,
        LogsLevel.debug,
        LogsLevel.info,
        LogsLevel.warn,
        LogsLevel.error,
        LogsLevel.fatal,
        LogsLevel.off,
      ]);
    });
  });

  group("LogsLevel.parseFromString", () {
    test("returns the level matching its name", () {
      expect(LogsLevel.parseFromString("trace"), LogsLevel.trace);
      expect(LogsLevel.parseFromString("debug"), LogsLevel.debug);
      expect(LogsLevel.parseFromString("info"), LogsLevel.info);
      expect(LogsLevel.parseFromString("warn"), LogsLevel.warn);
      expect(LogsLevel.parseFromString("error"), LogsLevel.error);
      expect(LogsLevel.parseFromString("fatal"), LogsLevel.fatal);
      expect(LogsLevel.parseFromString("all"), LogsLevel.all);
    });

    test("returns the level matching its single letter shortcut", () {
      expect(LogsLevel.parseFromString("t"), LogsLevel.trace);
      expect(LogsLevel.parseFromString("d"), LogsLevel.debug);
      expect(LogsLevel.parseFromString("i"), LogsLevel.info);
      expect(LogsLevel.parseFromString("w"), LogsLevel.warn);
      expect(LogsLevel.parseFromString("e"), LogsLevel.error);
      expect(LogsLevel.parseFromString("f"), LogsLevel.fatal);
      expect(LogsLevel.parseFromString("n"), LogsLevel.off);
    });

    test("returns the level matching one of its aliases", () {
      expect(LogsLevel.parseFromString("information"), LogsLevel.info);
      expect(LogsLevel.parseFromString("warning"), LogsLevel.warn);
      expect(LogsLevel.parseFromString("none"), LogsLevel.off);
      expect(LogsLevel.parseFromString("off"), LogsLevel.off);
    });

    test("ignores the case of the value", () {
      expect(LogsLevel.parseFromString("WARN"), LogsLevel.warn);
      expect(LogsLevel.parseFromString("Warning"), LogsLevel.warn);
    });

    test("returns null when the value matches no level", () {
      expect(LogsLevel.parseFromString("verbose"), isNull);
    });

    test("returns null when the value is empty", () {
      expect(LogsLevel.parseFromString(""), isNull);
    });

    test("returns null when the value is surrounded by spaces", () {
      expect(LogsLevel.parseFromString(" warn "), isNull);
    });
  });
}
