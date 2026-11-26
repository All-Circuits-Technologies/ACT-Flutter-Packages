// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/types/env_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("EnvType.parseFromString", () {
    test("parses the names of a string variable", () {
      expect(EnvType.parseFromString("string"), EnvType.string);
      expect(EnvType.parseFromString("str"), EnvType.string);
    });

    test("parses the names of a boolean variable", () {
      expect(EnvType.parseFromString("bool"), EnvType.bool);
      expect(EnvType.parseFromString("boolean"), EnvType.bool);
    });

    test("parses the names of a number variable", () {
      expect(EnvType.parseFromString("num"), EnvType.number);
      expect(EnvType.parseFromString("number"), EnvType.number);
      expect(EnvType.parseFromString("int"), EnvType.number);
      expect(EnvType.parseFromString("integer"), EnvType.number);
      expect(EnvType.parseFromString("decimal"), EnvType.number);
      expect(EnvType.parseFromString("float"), EnvType.number);
    });

    test("parses the names of a yaml variable", () {
      expect(EnvType.parseFromString("yaml"), EnvType.yaml);
      expect(EnvType.parseFromString("yml"), EnvType.yaml);
      expect(EnvType.parseFromString("json"), EnvType.yaml);
    });

    test("ignores the case of the given name", () {
      expect(EnvType.parseFromString("STRING"), EnvType.string);
      expect(EnvType.parseFromString("Boolean"), EnvType.bool);
    });

    test("returns null when the name is unknown", () {
      expect(EnvType.parseFromString("date"), isNull);
      expect(EnvType.parseFromString("double"), isNull);
    });

    test("returns null for a name which is only a part of a known one", () {
      expect(EnvType.parseFromString("strin"), isNull);
      expect(EnvType.parseFromString("b"), isNull);
      expect(EnvType.parseFromString("ing"), isNull);
    });

    test("returns null when the name is empty", () {
      expect(EnvType.parseFromString(""), isNull);
    });
  });
}
