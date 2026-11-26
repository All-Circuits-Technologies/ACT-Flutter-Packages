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
        "server": {"url": "https://example.com/api", "port": 8080, "timeout": "not a number"},
      },
    ),
  );

  tearDown(() => ConfigSingleton.instanceOrNull?.disposeLifeCycle());

  group("ParserConfigVar.load", () {
    test("returns the parsed value stored at its key", () {
      expect(
        const ParserConfigVar<Uri, String>("server.url", parser: Uri.tryParse).load(),
        Uri.parse("https://example.com/api"),
      );
    });

    test("returns null when its key is missing", () {
      expect(
        const ParserConfigVar<Uri, String>("server.host", parser: Uri.tryParse).load(),
        isNull,
      );
    });

    test("returns null when the stored value is not of the type the parser reads", () {
      expect(
        const ParserConfigVar<Uri, String>("server.port", parser: Uri.tryParse).load(),
        isNull,
      );
    });

    test("returns null when the parsing fails", () {
      expect(
        const ParserConfigVar<int, String>("server.timeout", parser: int.tryParse).load(),
        isNull,
      );
    });

    test("gives the stored value to its parser", () {
      final parsed = <String>[];

      ParserConfigVar<String, String>(
        "server.url",
        parser: (value) {
          parsed.add(value);
          return value;
        },
      ).load();

      expect(parsed, ["https://example.com/api"]);
    });
  });

  group("ParserConfigVar", () {
    test("has a value equality on its key", () {
      expect(
        const ParserConfigVar<Uri, String>("server.url", parser: Uri.tryParse),
        const ParserConfigVar<Uri, String>("server.url", parser: Uri.tryParse),
      );
      expect(
        const ParserConfigVar<Uri, String>("server.url", parser: Uri.tryParse),
        isNot(const ParserConfigVar<Uri, String>("server.host", parser: Uri.tryParse)),
      );
    });
  });
}
