// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:test/test.dart';

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    ConfigStore.create(
      logger: logger,
      configs: {
        "server": {
          "hosts": ["first", "second"],
          "name": "main",
        },
      },
    );
  });

  tearDown(() => ConfigStore.instanceOrNull?.dispose());

  group("NotNullableConfigVarList.load", () {
    test("returns the list stored at its key", () {
      expect(
        const NotNullableConfigVarList<String>("server.hosts", defaultValues: ["third"]).load(),
        ["first", "second"],
      );
    });

    test("returns its default values when its key is missing", () {
      expect(
        const NotNullableConfigVarList<String>("server.names", defaultValues: ["third"]).load(),
        ["third"],
      );
    });

    test("returns its default values when the stored value is not a list", () {
      expect(
        const NotNullableConfigVarList<String>("server.name", defaultValues: ["third"]).load(),
        ["third"],
      );
    });
  });

  group("NotNullableConfigVarList.crashIfNull", () {
    test("returns the list stored at its key", () {
      expect(const NotNullableConfigVarList<String>.crashIfNull("server.hosts").load(), [
        "first",
        "second",
      ]);
    });

    test("throws when its key is missing", () {
      expect(
        () => const NotNullableConfigVarList<String>.crashIfNull("server.names").load(),
        throwsA(isA<ActConfigNullValueError>().having((error) => error.key, "key", "server.names")),
      );
    });

    test("logs an error before it throws", () {
      expect(
        () => const NotNullableConfigVarList<String>.crashIfNull("server.names").load(),
        throwsA(isA<ActConfigNullValueError>()),
      );

      expect(logger.recordsAtLevel(LogsLevel.error).length, 1);
    });
  });

  group("NotNullableConfigVarList", () {
    test("has a value equality on its key and its default values", () {
      expect(
        const NotNullableConfigVarList<String>("server.hosts", defaultValues: ["third"]),
        const NotNullableConfigVarList<String>("server.hosts", defaultValues: ["third"]),
      );
      expect(
        const NotNullableConfigVarList<String>("server.hosts", defaultValues: ["third"]),
        isNot(const NotNullableConfigVarList<String>("server.hosts", defaultValues: ["fourth"])),
      );
    });
  });
}
