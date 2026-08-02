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
        "server": {
          "hosts": ["first", "second"],
          "ports": [80, 443],
          "name": "main",
        },
      },
    ),
  );

  tearDown(() => ConfigSingleton.instanceOrNull?.disposeLifeCycle());

  group("ConfigVarList.load", () {
    test("returns the list stored at its key", () {
      expect(const ConfigVarList<String>("server.hosts").load(), ["first", "second"]);
    });

    test("returns null when its key is missing", () {
      expect(const ConfigVarList<String>("server.names").load(), isNull);
    });

    test("returns null when the stored value is not a list", () {
      expect(const ConfigVarList<String>("server.name").load(), isNull);
    });

    test("returns null when the elements of the list are not of its type", () {
      expect(const ConfigVarList<String>("server.ports").load(), isNull);
    });
  });

  group("ConfigVarList", () {
    test("has a value equality on its key", () {
      expect(
        const ConfigVarList<String>("server.hosts"),
        const ConfigVarList<String>("server.hosts"),
      );
      expect(
        const ConfigVarList<String>("server.hosts"),
        isNot(const ConfigVarList<String>("server.ports")),
      );
    });
  });
}
