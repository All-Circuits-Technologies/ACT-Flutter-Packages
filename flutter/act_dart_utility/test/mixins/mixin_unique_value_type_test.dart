// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// An enum whose values are identified by an integer, as a protocol would encode them.
enum _Command with MixinUniqueValueType<int> {
  start(1),
  stop(2);

  @override
  final int uniqueValue;

  const _Command(this.uniqueValue);
}

void main() {
  group("MixinUniqueValueType.uniqueValue", () {
    test("returns the value the enum carries", () {
      expect(_Command.start.uniqueValue, 1);
      expect(_Command.stop.uniqueValue, 2);
    });
  });

  group("MixinUniqueValueType.tryToParseFromUniqueValue", () {
    test("finds the value identified by the given one", () {
      expect(
        MixinUniqueValueType.tryToParseFromUniqueValue<int, _Command>(
          value: 2,
          values: _Command.values,
        ),
        _Command.stop,
      );
    });

    test("returns null when no value matches", () {
      expect(
        MixinUniqueValueType.tryToParseFromUniqueValue<int, _Command>(
          value: 3,
          values: _Command.values,
        ),
        isNull,
      );
    });

    test("returns null when the value is null", () {
      expect(
        MixinUniqueValueType.tryToParseFromUniqueValue<int, _Command>(
          value: null,
          values: _Command.values,
        ),
        isNull,
      );
    });

    test("only looks among the values it is given", () {
      expect(
        MixinUniqueValueType.tryToParseFromUniqueValue<int, _Command>(
          value: 2,
          values: const [_Command.start],
        ),
        isNull,
      );
    });
  });
}
