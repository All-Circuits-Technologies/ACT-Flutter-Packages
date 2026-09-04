// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_entity/act_entity.dart';
import 'package:flutter_test/flutter_test.dart';

/// An entity which only implements what the mixin leaves to it.
class _MinimalEntity with Entity {
  String? name;

  @override
  bool get isValid => name != null;

  @override
  Map<String, dynamic> toJson() => {"name": name};
}

/// An entity which reads itself back from a JSON map.
class _ParsingEntity extends _MinimalEntity {
  @override
  void parseFromJson(Map<String, dynamic> json) {
    name = json["name"] as String?;
  }
}

void main() {
  group("Entity.toJson", () {
    test("returns what the entity chose to expose", () {
      final entity = _MinimalEntity()..name = "a name";

      expect(entity.toJson(), {"name": "a name"});
    });
  });

  group("Entity.isValid", () {
    test("returns what the entity decided", () {
      final entity = _MinimalEntity();

      expect(entity.isValid, isFalse);

      entity.name = "a name";

      expect(entity.isValid, isTrue);
    });
  });

  group("Entity.parseFromJson", () {
    test("leaves the entity untouched when it is not overridden", () {
      final entity = _MinimalEntity()..name = "a name";

      entity.parseFromJson({"name": "another name"});

      expect(entity.name, "a name");
    });

    test("does not throw on an empty map when it is not overridden", () {
      final entity = _MinimalEntity();

      expect(() => entity.parseFromJson({}), returnsNormally);
    });

    test("fills the entity when it is overridden", () {
      final entity = _ParsingEntity();

      entity.parseFromJson({"name": "a name"});

      expect(entity.name, "a name");
      expect(entity.isValid, isTrue);
    });

    test("reads back what toJson produced", () {
      final entity = _ParsingEntity()..name = "a name";
      final otherEntity = _ParsingEntity()..parseFromJson(entity.toJson());

      expect(otherEntity.toJson(), entity.toJson());
    });
  });
}
