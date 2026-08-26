// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_yaml_utility/act_yaml_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("YamlFromString.fromYaml", () {
    test("parses a YAML object", () {
      expect(YamlFromString.fromYaml("a: 1\nb: two"), {"a": 1, "b": "two"});
    });

    test("parses a YAML list", () {
      expect(YamlFromString.fromYaml("- 1\n- 2"), [1, 2]);
    });

    test("parses a JSON content, which is valid YAML", () {
      expect(YamlFromString.fromYaml('{"a": 1}'), {"a": 1});
    });

    test("drops the comments", () {
      expect(YamlFromString.fromYaml("# a comment\na: 1"), {"a": 1});
    });

    test("returns plain Dart objects and not YAML ones", () {
      final parsed = YamlFromString.fromYamlMap("a:\n  b: 1");

      expect(parsed, isA<Map<String, dynamic>>());
      expect(parsed!["a"], isA<Map<String, dynamic>>());
    });

    test("returns null for an empty content", () {
      expect(YamlFromString.fromYaml(""), isNull);
    });

    test("returns null when the content is not YAML", () {
      expect(YamlFromString.fromYaml("a:\n  - 1\n b: 2"), isNull);
    });
  });

  group("YamlFromString.fromYamlMap", () {
    test("returns the object at the root of the content", () {
      expect(YamlFromString.fromYamlMap("a: 1"), {"a": 1});
    });

    test("returns null when the root is a list", () {
      expect(YamlFromString.fromYamlMap("- 1"), isNull);
    });

    test("returns null when the root is a scalar", () {
      expect(YamlFromString.fromYamlMap("42"), isNull);
    });

    test("returns null when the content is not YAML", () {
      expect(YamlFromString.fromYamlMap("a:\n  - 1\n b: 2"), isNull);
    });
  });

  group("YamlFromString.fromYamlList", () {
    test("returns the list at the root of the content", () {
      expect(YamlFromString.fromYamlList("- 1\n- 2"), [1, 2]);
    });

    test("returns null when the root is an object", () {
      expect(YamlFromString.fromYamlList("a: 1"), isNull);
    });

    test("returns null when the content is not YAML", () {
      expect(YamlFromString.fromYamlList("a:\n  - 1\n b: 2"), isNull);
    });
  });
}
