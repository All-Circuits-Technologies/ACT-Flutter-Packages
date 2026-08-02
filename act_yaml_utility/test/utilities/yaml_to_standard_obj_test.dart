// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_yaml_utility/act_yaml_utility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group("YamlToStandardObj.fromYamlMap", () {
    test("returns a map which is a plain Dart one", () {
      final converted = YamlToStandardObj.fromYamlMap(loadYaml("a: 1") as YamlMap);

      expect(converted, isA<Map<String, dynamic>>());
      expect(converted, isNot(isA<YamlMap>()));
      expect(converted, {"a": 1});
    });

    test("converts the nested maps as well", () {
      final converted = YamlToStandardObj.fromYamlMap(
        loadYaml("server:\n  host: example.com") as YamlMap,
      );

      expect(converted["server"], isA<Map<String, dynamic>>());
      expect(converted, {
        "server": {"host": "example.com"},
      });
    });

    test("converts the nested lists as well", () {
      final converted = YamlToStandardObj.fromYamlMap(
        loadYaml("items:\n  - 1\n  - 2") as YamlMap,
      );

      expect(converted["items"], isA<List<dynamic>>());
      expect(converted, {
        "items": [1, 2],
      });
    });

    test("returns an empty map for an empty one", () {
      expect(YamlToStandardObj.fromYamlMap(loadYaml("{}") as YamlMap), isEmpty);
    });
  });

  group("YamlToStandardObj.fromYamlList", () {
    test("returns a list which is a plain Dart one", () {
      final converted = YamlToStandardObj.fromYamlList(loadYaml("- 1\n- 2") as YamlList);

      expect(converted, isNot(isA<YamlList>()));
      expect(converted, [1, 2]);
    });

    test("converts the maps it holds", () {
      final converted = YamlToStandardObj.fromYamlList(loadYaml("- a: 1") as YamlList);

      expect(converted.first, isA<Map<String, dynamic>>());
    });

    test("returns an empty list for an empty one", () {
      expect(YamlToStandardObj.fromYamlList(loadYaml("[]") as YamlList), isEmpty);
    });
  });

  group("YamlToStandardObj.fromDoc", () {
    test("converts the content of the document", () {
      expect(YamlToStandardObj.fromDoc(loadYamlDocument("a: 1")), {"a": 1});
    });

    test("drops the comments of the document", () {
      expect(YamlToStandardObj.fromDoc(loadYamlDocument("# a comment\na: 1")), {"a": 1});
    });

    test("converts a document whose content is a scalar", () {
      expect(YamlToStandardObj.fromDoc(loadYamlDocument("42")), 42);
    });
  });

  group("YamlToStandardObj.fromDocs", () {
    test("converts every document of the stream", () {
      final documents = loadYamlDocuments("a: 1\n---\nb: 2");

      expect(YamlToStandardObj.fromDocs(documents), [
        {"a": 1},
        {"b": 2},
      ]);
    });

    test("returns an empty list when there is no document", () {
      expect(YamlToStandardObj.fromDocs(const []), isEmpty);
    });
  });

  group("YamlToStandardObj.fromYamlValue", () {
    test("converts the maps and the lists", () {
      expect(YamlToStandardObj.fromYamlValue(loadYaml("a: 1")), {"a": 1});
      expect(YamlToStandardObj.fromYamlValue(loadYaml("- 1")), [1]);
    });

    test("converts a document and a list of documents", () {
      expect(YamlToStandardObj.fromYamlValue(loadYamlDocument("a: 1")), {"a": 1});
      expect(YamlToStandardObj.fromYamlValue(loadYamlDocuments("a: 1")), [
        {"a": 1},
      ]);
    });

    test("returns the scalar values as they are", () {
      expect(YamlToStandardObj.fromYamlValue(42), 42);
      expect(YamlToStandardObj.fromYamlValue("a value"), "a value");
      expect(YamlToStandardObj.fromYamlValue(true), isTrue);
      expect(YamlToStandardObj.fromYamlValue(null), isNull);
    });

    test("keeps the types the YAML parser gave to the values", () {
      final converted = YamlToStandardObj.fromYamlValue(
        loadYaml("count: 1\nratio: 1.5\nenabled: true\nname: a name\nempty:"),
      );

      expect(converted, {
        "count": 1,
        "ratio": 1.5,
        "enabled": true,
        "name": "a name",
        "empty": null,
      });
    });
  });
}
