// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// An enum whose values are named after themselves, except the one which overrides its value.
enum _Kind with MixinStringValueType {
  first,
  second,
  thirdOne("third-one");

  @override
  final String? stringValueOverride;

  const _Kind([this.stringValueOverride]);
}

void main() {
  group("MixinStringValueType.stringValue", () {
    test("returns the name of the value when there is no override", () {
      expect(_Kind.first.stringValue, "first");
      expect(_Kind.second.stringValue, "second");
    });

    test("returns the override when there is one", () {
      expect(_Kind.thirdOne.stringValue, "third-one");
    });
  });

  group("MixinStringValueType.tryToParseFromStringValue", () {
    test("finds the value named by the string", () {
      expect(
        MixinStringValueType.tryToParseFromStringValue(value: "second", values: _Kind.values),
        _Kind.second,
      );
    });

    test("finds the value through its override", () {
      expect(
        MixinStringValueType.tryToParseFromStringValue(value: "third-one", values: _Kind.values),
        _Kind.thirdOne,
      );
    });

    test("ignores the case of the value", () {
      expect(
        MixinStringValueType.tryToParseFromStringValue(value: "SECOND", values: _Kind.values),
        _Kind.second,
      );
    });

    test("does not find a value through its name when it has an override", () {
      expect(
        MixinStringValueType.tryToParseFromStringValue(value: "thirdOne", values: _Kind.values),
        isNull,
      );
    });

    test("returns null when no value matches", () {
      expect(
        MixinStringValueType.tryToParseFromStringValue(value: "fourth", values: _Kind.values),
        isNull,
      );
    });

    test("returns null when the value is null", () {
      expect(
        MixinStringValueType.tryToParseFromStringValue(value: null, values: _Kind.values),
        isNull,
      );
    });

    test("only looks among the values it is given", () {
      expect(
        MixinStringValueType.tryToParseFromStringValue(
          value: "second",
          values: const [_Kind.first],
        ),
        isNull,
      );
    });
  });
}
