// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_config_manager/src/services/config_singleton.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(
    () => ConfigSingleton.createInstance(
      logger: const SilentLogger(),
      configs: {
        "logs": {"level": "warning", "logsNb": 3},
      },
    ),
  );

  tearDown(() => ConfigSingleton.instanceOrNull?.disposeLifeCycle());

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
