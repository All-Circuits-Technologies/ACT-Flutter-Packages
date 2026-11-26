// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:act_dart_test_utility/act_dart_test_utility.dart';
import 'package:test/test.dart';

void main() {
  setUp(
    () => ConfigStore.create(
      logger: const SilentLogger(),
      configs: {
        "logs": {"level": "warning", "logsNb": 3},
      },
    ),
  );

  tearDown(() => ConfigStore.instanceOrNull?.dispose());

  group("ConfigVar.load", () {
    test("returns the value stored at its key", () {
      expect(const ConfigVar<String>("logs.level").load(), "warning");
    });

    test("returns null when its key is missing", () {
      expect(const ConfigVar<String>("logs.console.level").load(), isNull);
    });

    test("returns null when the stored value is not of its type", () {
      expect(const ConfigVar<String>("logs.logsNb").load(), isNull);
    });
  });

  group("ConfigVar", () {
    test("has a value equality on its key", () {
      expect(const ConfigVar<String>("logs.level"), const ConfigVar<String>("logs.level"));
      expect(
        const ConfigVar<String>("logs.level"),
        isNot(const ConfigVar<String>("logs.console.level")),
      );
    });
  });
}
