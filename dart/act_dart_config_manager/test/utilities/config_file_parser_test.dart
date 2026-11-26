// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/act_dart_config_manager.dart';
import 'package:test/test.dart';

void main() {
  group("ConfigFileParser.fromContent", () {
    test("returns an empty map when the content is null", () {
      expect(ConfigFileParser.fromContent(null, description: "default"), isEmpty);
    });

    test("returns an empty map when the content is empty or blank", () {
      expect(ConfigFileParser.fromContent("", description: "default"), isEmpty);
      expect(ConfigFileParser.fromContent("   \n  ", description: "default"), isEmpty);
    });

    test("returns the structured config of a YAML content", () {
      final config = ConfigFileParser.fromContent(
        "logs:\n  level: warning",
        description: "default",
      );

      expect(config, {
        "logs": {"level": "warning"},
      });
    });

    test("reads a JSON content as well as a YAML one", () {
      final config = ConfigFileParser.fromContent(
        '{"logs": {"level": "warning"}}',
        description: "default",
      );

      expect(config, {
        "logs": {"level": "warning"},
      });
    });

    test("throws when the content cannot be parsed", () {
      expect(
        () => ConfigFileParser.fromContent("logs:\n  - level\n level: warning", description: "d"),
        throwsA(isA<ActConfigLoadException>()),
      );
    });

    test("throws when the content is not a map", () {
      expect(
        () => ConfigFileParser.fromContent("- first\n- second", description: "d"),
        throwsA(isA<ActConfigMappingFormatException>()),
      );
    });
  });
}
