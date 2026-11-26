// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_config_manager/src/errors/act_config_null_value_error.dart';
import 'package:act_config_manager/src/services/config_singleton.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    ConfigSingleton.createInstance(
      logger: logger,
      configs: {
        "logs": {"level": "warning", "logsNb": 3},
      },
    );
  });

  tearDown(() => ConfigSingleton.instanceOrNull?.disposeLifeCycle());

  group("NotNullableConfigVar.load", () {
    test("returns the value stored at its key", () {
      expect(
        const NotNullableConfigVar<String>("logs.level", defaultValue: "info").load(),
        "warning",
      );
    });

    test("returns its default value when its key is missing", () {
      expect(
        const NotNullableConfigVar<String>("logs.console.level", defaultValue: "info").load(),
        "info",
      );
    });

    test("returns its default value when the stored value is not of its type", () {
      expect(
        const NotNullableConfigVar<String>("logs.logsNb", defaultValue: "info").load(),
        "info",
      );
    });
  });

  group("NotNullableConfigVar.crashIfNull", () {
    test("returns the value stored at its key", () {
      expect(const NotNullableConfigVar<String>.crashIfNull("logs.level").load(), "warning");
    });

    test("throws when its key is missing", () {
      expect(
        () => const NotNullableConfigVar<String>.crashIfNull("logs.console.level").load(),
        throwsA(
          isA<ActConfigNullValueError>().having((error) => error.key, "key", "logs.console.level"),
        ),
      );
    });

    test("logs an error before it throws", () {
      expect(
        () => const NotNullableConfigVar<String>.crashIfNull("logs.console.level").load(),
        throwsA(isA<ActConfigNullValueError>()),
      );

      expect(logger.recordsAtLevel(LogsLevel.error).length, 1);
    });
  });

  group("NotNullableConfigVar", () {
    test("has a value equality on its key and its default value", () {
      expect(
        const NotNullableConfigVar<String>("logs.level", defaultValue: "info"),
        const NotNullableConfigVar<String>("logs.level", defaultValue: "info"),
      );
      expect(
        const NotNullableConfigVar<String>("logs.level", defaultValue: "info"),
        isNot(const NotNullableConfigVar<String>("logs.level", defaultValue: "warning")),
      );
      expect(
        const NotNullableConfigVar<String>("logs.level", defaultValue: "info"),
        isNot(const NotNullableConfigVar<String>.crashIfNull("logs.level")),
      );
    });
  });
}
