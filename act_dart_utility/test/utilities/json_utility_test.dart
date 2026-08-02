// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeLogger logger;

  setUp(() => logger = FakeLogger());

  group("JsonUtility.getOneElement", () {
    test("returns the value stored at the key", () {
      final result = JsonUtility.getOneElement<int, int>(
        json: {"count": 42},
        key: "count",
        logger: logger,
      );

      expect(result, (isOk: true, value: 42));
    });

    test("fails when the key is missing", () {
      final result = JsonUtility.getOneElement<int, int>(
        json: const {},
        key: "count",
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("succeeds without any value when the key is allowed to be missing", () {
      final result = JsonUtility.getOneElement<int, int>(
        json: const {},
        key: "count",
        canBeUndefined: true,
        logger: logger,
      );

      expect(result, (isOk: true, value: null));
      expect(logger.records, isEmpty);
    });

    test("treats a null value as a missing key", () {
      final result = JsonUtility.getOneElement<int, int>(
        json: const {"count": null},
        key: "count",
        canBeUndefined: true,
        logger: logger,
      );

      expect(result, (isOk: true, value: null));
    });

    test("fails when the value has another type", () {
      final result = JsonUtility.getOneElement<int, int>(
        json: const {"count": "42"},
        key: "count",
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });

    test("casts the value with the given function", () {
      final result = JsonUtility.getOneElement<Duration, int>(
        json: const {"delay": 30},
        key: "delay",
        castValueFunc: DurationUtility.parseFromSeconds,
        logger: logger,
      );

      expect(result, (isOk: true, value: const Duration(seconds: 30)));
    });

    test("fails when the cast function refuses the value", () {
      final result = JsonUtility.getOneElement<Duration, int>(
        json: const {"delay": -1},
        key: "delay",
        castValueFunc: DurationUtility.parseFromSeconds,
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });

    test("fails when the value cannot be given to the cast function", () {
      final result = JsonUtility.getOneElement<Duration, int>(
        json: const {"delay": "30"},
        key: "delay",
        castValueFunc: DurationUtility.parseFromSeconds,
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });
  });

  group("JsonUtility.getOnePrimaryElement", () {
    test("returns the value stored at the key", () {
      final result = JsonUtility.getOnePrimaryElement<String>(
        json: const {"name": "a name"},
        key: "name",
        logger: logger,
      );

      expect(result, (isOk: true, value: "a name"));
    });

    test("fails when the value has another type", () {
      final result = JsonUtility.getOnePrimaryElement<String>(
        json: const {"name": 42},
        key: "name",
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });
  });

  group("JsonUtility.getNotNullOneElement", () {
    test("returns the value stored at the key", () {
      expect(
        JsonUtility.getNotNullOneElement<int, int>(
          json: const {"count": 42},
          key: "count",
          logger: logger,
        ),
        42,
      );
    });

    test("returns null when the key is missing", () {
      expect(
        JsonUtility.getNotNullOneElement<int, int>(json: const {}, key: "count", logger: logger),
        isNull,
      );
    });
  });

  group("JsonUtility.getNotNullOnePrimaryElement", () {
    test("returns the value stored at the key", () {
      expect(
        JsonUtility.getNotNullOnePrimaryElement<bool>(
          json: const {"enabled": true},
          key: "enabled",
          logger: logger,
        ),
        isTrue,
      );
    });
  });

  group("JsonUtility.getElementsList", () {
    test("returns the list stored at the key", () {
      final result = JsonUtility.getElementsList<int, int>(
        json: const {
          "counts": [1, 2],
        },
        key: "counts",
        logger: logger,
      );

      expect(result.isOk, isTrue);
      expect(result.value, [1, 2]);
    });

    test("returns an empty list for an empty one", () {
      final result = JsonUtility.getElementsList<int, int>(
        json: const {"counts": <dynamic>[]},
        key: "counts",
        logger: logger,
      );

      expect(result.isOk, isTrue);
      expect(result.value, isEmpty);
    });

    test("casts every element with the given function", () {
      final result = JsonUtility.getElementsList<Duration, int>(
        json: const {
          "delays": [1, 2],
        },
        key: "delays",
        castElemValueFunc: DurationUtility.parseFromSeconds,
        logger: logger,
      );

      expect(result.isOk, isTrue);
      expect(result.value, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });

    test("fails as a whole when one element cannot be cast", () {
      final result = JsonUtility.getElementsList<Duration, int>(
        json: const {
          "delays": [1, -2],
        },
        key: "delays",
        castElemValueFunc: DurationUtility.parseFromSeconds,
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });

    test("fails when one element has another type", () {
      final result = JsonUtility.getElementsList<int, int>(
        json: const {
          "counts": [1, "two"],
        },
        key: "counts",
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });

    test("fails when the value is not a list", () {
      final result = JsonUtility.getElementsList<int, int>(
        json: const {"counts": 1},
        key: "counts",
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });
  });

  group("JsonUtility.getPrimaryElementsList", () {
    test("returns the list stored at the key", () {
      final result = JsonUtility.getPrimaryElementsList<String>(
        json: const {
          "names": ["a", "b"],
        },
        key: "names",
        logger: logger,
      );

      expect(result.isOk, isTrue);
      expect(result.value, ["a", "b"]);
    });
  });

  group("JsonUtility.getNotNullElementsList", () {
    test("returns the list stored at the key", () {
      expect(
        JsonUtility.getNotNullElementsList<int, int>(
          json: const {
            "counts": [1],
          },
          key: "counts",
          logger: logger,
        ),
        [1],
      );
    });

    test("returns null when the key is missing", () {
      expect(
        JsonUtility.getNotNullElementsList<int, int>(
          json: const {},
          key: "counts",
          logger: logger,
        ),
        isNull,
      );
    });
  });

  group("JsonUtility.getNotNullPrimaryElementsList", () {
    test("returns the list stored at the key", () {
      expect(
        JsonUtility.getNotNullPrimaryElementsList<int>(
          json: const {
            "counts": [1, 2],
          },
          key: "counts",
          logger: logger,
        ),
        [1, 2],
      );
    });
  });

  group("JsonUtility.getJsonObject", () {
    test("returns the object stored at the key", () {
      final result = JsonUtility.getJsonObject(
        json: const {
          "user": {"name": "a name"},
        },
        key: "user",
        logger: logger,
      );

      expect(result.isOk, isTrue);
      expect(result.value, {"name": "a name"});
    });

    test("fails when the value is not an object", () {
      final result = JsonUtility.getJsonObject(
        json: const {"user": 42},
        key: "user",
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });

    test("succeeds without any value when the key is allowed to be missing", () {
      final result = JsonUtility.getJsonObject(
        json: const {},
        key: "user",
        canBeUndefined: true,
        logger: logger,
      );

      expect(result, (isOk: true, value: null));
    });
  });

  group("JsonUtility.getNotNullJsonObject", () {
    test("returns the object stored at the key", () {
      expect(
        JsonUtility.getNotNullJsonObject(
          json: const {
            "user": {"name": "a name"},
          },
          key: "user",
          logger: logger,
        ),
        {"name": "a name"},
      );
    });

    test("returns null when the key is missing", () {
      expect(
        JsonUtility.getNotNullJsonObject(json: const {}, key: "user", logger: logger),
        isNull,
      );
    });
  });

  group("JsonUtility.getJsonObjectsList", () {
    test("returns the objects stored at the key", () {
      final result = JsonUtility.getJsonObjectsList(
        json: const {
          "users": [
            {"name": "a"},
            {"name": "b"},
          ],
        },
        key: "users",
        logger: logger,
      );

      expect(result.isOk, isTrue);
      expect(result.value, [
        {"name": "a"},
        {"name": "b"},
      ]);
    });

    test("fails when one element is not an object", () {
      final result = JsonUtility.getJsonObjectsList(
        json: const {
          "users": [
            {"name": "a"},
            42,
          ],
        },
        key: "users",
        logger: logger,
      );

      expect(result, (isOk: false, value: null));
    });
  });

  group("JsonUtility.getNotNullJsonObjectsList", () {
    test("returns the objects stored at the key", () {
      expect(
        JsonUtility.getNotNullJsonObjectsList(
          json: const {
            "users": [
              {"name": "a"},
            ],
          },
          key: "users",
          logger: logger,
        ),
        [
          {"name": "a"},
        ],
      );
    });

    test("returns null when the key is missing", () {
      expect(
        JsonUtility.getNotNullJsonObjectsList(json: const {}, key: "users", logger: logger),
        isNull,
      );
    });
  });

  group("JsonUtility.parseJsonBodyToObj", () {
    test("parses a JSON object", () {
      expect(
        JsonUtility.parseJsonBodyToObj('{"name":"a name"}', logger: logger),
        {"name": "a name"},
      );
    });

    test("returns null when the body is null", () {
      expect(JsonUtility.parseJsonBodyToObj(null, logger: logger), isNull);
    });

    test("returns null when the body is not JSON", () {
      expect(JsonUtility.parseJsonBodyToObj("not json", logger: logger), isNull);
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("returns null when the body is a JSON array", () {
      expect(JsonUtility.parseJsonBodyToObj("[1, 2]", logger: logger), isNull);
    });
  });

  group("JsonUtility.parseJsonBodyToArray", () {
    test("parses a JSON array", () {
      expect(JsonUtility.parseJsonBodyToArray("[1, 2]", logger: logger), [1, 2]);
    });

    test("returns null when the body is a JSON object", () {
      expect(JsonUtility.parseJsonBodyToArray('{"a":1}', logger: logger), isNull);
    });
  });

  group("JsonUtility.parseJsonArrayBodyToArray", () {
    test("parses an array of JSON objects", () {
      expect(
        JsonUtility.parseJsonArrayBodyToArray('[{"name":"a"}]', logger: logger),
        [
          {"name": "a"},
        ],
      );
    });

    test("returns null when an element is not an object", () {
      expect(JsonUtility.parseJsonArrayBodyToArray("[1]", logger: logger), isNull);
      expect(logger.recordsAtLevel(LogsLevel.warn).length, 1);
    });

    test("returns null when the body is not JSON", () {
      expect(JsonUtility.parseJsonArrayBodyToArray("not json", logger: logger), isNull);
    });
  });

  group("JsonUtility.mergeJson", () {
    test("adds the keys which are only in the overriding object", () {
      expect(
        JsonUtility.mergeJson(baseJson: const {"a": 1}, jsonToOverrideWith: const {"b": 2}),
        {"a": 1, "b": 2},
      );
    });

    test("keeps the keys which are only in the base object", () {
      expect(
        JsonUtility.mergeJson(baseJson: const {"a": 1}, jsonToOverrideWith: const {}),
        {"a": 1},
      );
    });

    test("overrides the value of a key which is in both objects", () {
      expect(
        JsonUtility.mergeJson(baseJson: const {"a": 1}, jsonToOverrideWith: const {"a": 2}),
        {"a": 2},
      );
    });

    test("merges the nested objects in depth", () {
      expect(
        JsonUtility.mergeJson(
          baseJson: const {
            "server": {"host": "example.com", "port": 80},
          },
          jsonToOverrideWith: const {
            "server": {"port": 443},
          },
        ),
        {
          "server": {"host": "example.com", "port": 443},
        },
      );
    });

    test("replaces the value when the two types differ", () {
      expect(
        JsonUtility.mergeJson(
          baseJson: const {
            "server": {"host": "example.com"},
          },
          jsonToOverrideWith: const {"server": "example.com"},
        ),
        {"server": "example.com"},
      );
    });

    test("keeps the base value when the overriding one is null", () {
      expect(
        JsonUtility.mergeJson(
          baseJson: const {"a": 1},
          jsonToOverrideWith: const {"a": null},
        ),
        {"a": 1},
      );
    });

    test("replaces a list instead of merging it", () {
      expect(
        JsonUtility.mergeJson(
          baseJson: const {
            "items": [1, 2],
          },
          jsonToOverrideWith: const {
            "items": [3],
          },
        ),
        {
          "items": [3],
        },
      );
    });

    test("leaves the base object untouched", () {
      final baseJson = <String, dynamic>{"a": 1};

      JsonUtility.mergeJson(baseJson: baseJson, jsonToOverrideWith: const {"b": 2});

      expect(baseJson, {"a": 1});
    });
  });
}
