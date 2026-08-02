// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_config_manager/src/errors/act_config_null_value_error.dart';
import 'package:act_config_manager/src/services/config_singleton.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The value returned when the configuration gives no url.
final _defaultUrl = Uri.parse("https://default.example.com");

void main() {
  late FakeLogger logger;

  setUp(() {
    logger = FakeLogger();
    ConfigSingleton.createInstance(
      logger: logger,
      configs: {
        "server": {"url": "https://example.com/api", "timeout": "not a number"},
      },
    );
  });

  tearDown(() => ConfigSingleton.instanceOrNull?.disposeLifeCycle());

  group("NotNullParserConfigVar.load", () {
    test("returns the parsed value stored at its key", () {
      expect(
        NotNullParserConfigVar<Uri, String>(
          "server.url",
          defaultValue: _defaultUrl,
          parser: Uri.tryParse,
        ).load(),
        Uri.parse("https://example.com/api"),
      );
    });

    test("returns its default value when its key is missing", () {
      expect(
        NotNullParserConfigVar<Uri, String>(
          "server.host",
          defaultValue: _defaultUrl,
          parser: Uri.tryParse,
        ).load(),
        _defaultUrl,
      );
    });

    test("returns its default value when the parsing fails", () {
      expect(
        const NotNullParserConfigVar<int, String>(
          "server.timeout",
          defaultValue: 30,
          parser: int.tryParse,
        ).load(),
        30,
      );
    });
  });

  group("NotNullParserConfigVar.crashIfNull", () {
    test("returns the parsed value stored at its key", () {
      expect(
        const NotNullParserConfigVar<Uri, String>.crashIfNull(
          "server.url",
          parser: Uri.tryParse,
        ).load(),
        Uri.parse("https://example.com/api"),
      );
    });

    test("throws when its key is missing", () {
      expect(
        () => const NotNullParserConfigVar<Uri, String>.crashIfNull(
          "server.host",
          parser: Uri.tryParse,
        ).load(),
        throwsA(isA<ActConfigNullValueError>().having((error) => error.key, "key", "server.host")),
      );
    });

    test("throws when the parsing fails", () {
      expect(
        () => const NotNullParserConfigVar<int, String>.crashIfNull(
          "server.timeout",
          parser: int.tryParse,
        ).load(),
        throwsA(isA<ActConfigNullValueError>()),
      );
    });

    test("logs an error before it throws", () {
      expect(
        () => const NotNullParserConfigVar<Uri, String>.crashIfNull(
          "server.host",
          parser: Uri.tryParse,
        ).load(),
        throwsA(isA<ActConfigNullValueError>()),
      );

      expect(logger.recordsAtLevel(LogsLevel.error).length, 1);
    });
  });

  group("NotNullParserConfigVar", () {
    test("has a value equality on its key and its default value", () {
      expect(
        const NotNullParserConfigVar<int, String>(
          "server.timeout",
          defaultValue: 30,
          parser: int.tryParse,
        ),
        const NotNullParserConfigVar<int, String>(
          "server.timeout",
          defaultValue: 30,
          parser: int.tryParse,
        ),
      );
      expect(
        const NotNullParserConfigVar<int, String>(
          "server.timeout",
          defaultValue: 30,
          parser: int.tryParse,
        ),
        isNot(
          const NotNullParserConfigVar<int, String>(
            "server.timeout",
            defaultValue: 60,
            parser: int.tryParse,
          ),
        ),
      );
    });
  });
}
