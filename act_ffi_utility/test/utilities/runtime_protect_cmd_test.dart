// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ffi' as ffi;

import 'package:act_ffi_utility/act_ffi_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    FakeGlobalManager.install(logger: logger);
  });

  group("RuntimeProtectCmd.protect", () {
    test("returns what the command answers", () {
      expect(RuntimeProtectCmd.protect<int>(() => 42), 42);
    });

    test("returns null when the command throws", () {
      expect(RuntimeProtectCmd.protect<int>(() => throw StateError("boom")), isNull);
    });

    test("warns about the command which threw", () {
      RuntimeProtectCmd.protect<int>(() => throw StateError("boom"));

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("says which command threw when the caller named it", () {
      RuntimeProtectCmd.protect<int>(
        () => throw StateError("boom"),
        description: "readTemperature",
      );

      expect(
        logger.recordsAtLevel(LogsLevel.warn).single.message.toString(),
        contains("readTemperature"),
      );
    });

    test("warns about nothing when the command answers", () {
      RuntimeProtectCmd.protect<int>(() => 42);

      expect(logger.records, isEmpty);
    });
  });

  group("RuntimeProtectCmd.protectWithDefault", () {
    test("returns what the command answers", () {
      expect(RuntimeProtectCmd.protectWithDefault<int>(() => 42, defaultValue: 0), 42);
    });

    test("returns the default value when the command throws", () {
      expect(
        RuntimeProtectCmd.protectWithDefault<int>(
          () => throw StateError("boom"),
          defaultValue: 0,
        ),
        0,
      );
    });

    test("returns the default value when the command answers null", () {
      expect(RuntimeProtectCmd.protectWithDefault<int?>(() => null, defaultValue: 0), 0);
    });
  });

  group("RuntimeProtectCmd.protectWithCalloc", () {
    test("returns what the command answers", () {
      expect(RuntimeProtectCmd.protectWithCalloc<int>((register) => 42), 42);
    });

    test("gives the command a register to allocate with", () {
      final answer = RuntimeProtectCmd.protectWithCalloc<int>((register) {
        final pointer = register.add(calloc<ffi.Int32>())..value = 42;

        return pointer.value;
      });

      expect(answer, 42);
    });

    test("frees what the command allocated", () {
      RuntimeCallocRegister? given;

      RuntimeProtectCmd.protectWithCalloc<void>((register) {
        given = register;
        register.add(calloc<ffi.Int32>());
      });

      expect(given, RuntimeCallocRegister());
    });

    test("frees what the command allocated before it threw", () {
      RuntimeCallocRegister? given;

      RuntimeProtectCmd.protectWithCalloc<void>((register) {
        given = register;
        register.add(calloc<ffi.Int32>());

        throw StateError("boom");
      });

      expect(given, RuntimeCallocRegister());
    });

    test("returns null when the command throws", () {
      expect(
        RuntimeProtectCmd.protectWithCalloc<int>((register) => throw StateError("boom")),
        isNull,
      );
    });

    test("warns about the command which threw", () {
      RuntimeProtectCmd.protectWithCalloc<int>((register) => throw StateError("boom"));

      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });
  });

  group("RuntimeProtectCmd.protectWithCallocAndDefault", () {
    test("returns what the command answers", () {
      expect(
        RuntimeProtectCmd.protectWithCallocAndDefault<int>((register) => 42, defaultValue: 0),
        42,
      );
    });

    test("returns the default value when the command throws", () {
      expect(
        RuntimeProtectCmd.protectWithCallocAndDefault<int>(
          (register) => throw StateError("boom"),
          defaultValue: 0,
        ),
        0,
      );
    });
  });
}
