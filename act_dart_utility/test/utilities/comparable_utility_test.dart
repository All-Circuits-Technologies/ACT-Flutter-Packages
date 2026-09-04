// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("ComparableUtility.compareToWithDefault", () {
    test("compares the two values when neither is null", () {
      expect(
        ComparableUtility.compareToWithDefault(base: 5, toCompareWith: 3, defaultValue: 0),
        greaterThan(0),
      );
    });

    test("uses the default value in place of a null base", () {
      expect(
        ComparableUtility.compareToWithDefault(base: null, toCompareWith: 3, defaultValue: 0),
        lessThan(0),
      );
    });

    test("uses the default value in place of a null value to compare with", () {
      expect(
        ComparableUtility.compareToWithDefault(base: 5, toCompareWith: null, defaultValue: 0),
        greaterThan(0),
      );
    });

    test("says the values are equal when both are null", () {
      expect(
        ComparableUtility.compareToWithDefault(base: null, toCompareWith: null, defaultValue: 0),
        ComparableUtility.defaultEqualValue,
      );
    });

    test("compares a null value with the default one and not with the other value", () {
      expect(
        ComparableUtility.compareToWithDefault(base: null, toCompareWith: -3, defaultValue: 0),
        greaterThan(0),
      );
    });
  });

  group("ComparableUtility.compareToNullable", () {
    test("compares the two values when neither is null", () {
      expect(ComparableUtility.compareToNullable(base: 5, toCompareWith: 3), greaterThan(0));
    });

    test("says the values are equal when both are null", () {
      expect(
        ComparableUtility.compareToNullable<num>(base: null, toCompareWith: null),
        ComparableUtility.defaultEqualValue,
      );
    });

    test("puts a null value first by default", () {
      expect(
        ComparableUtility.compareToNullable(base: null, toCompareWith: 3),
        ComparableUtility.defaultSmallerValue,
      );
      expect(
        ComparableUtility.compareToNullable(base: 3, toCompareWith: null),
        ComparableUtility.defaultBiggerValue,
      );
    });

    test("puts a null value last when it is asked to", () {
      expect(
        ComparableUtility.compareToNullable(base: null, toCompareWith: 3, nullIsBigger: true),
        ComparableUtility.defaultBiggerValue,
      );
      expect(
        ComparableUtility.compareToNullable(base: 3, toCompareWith: null, nullIsBigger: true),
        ComparableUtility.defaultSmallerValue,
      );
    });
  });

  group("ComparableUtility.isBaseLesserOrEqualTo", () {
    test("returns true when the base is smaller", () {
      expect(ComparableUtility.isBaseLesserOrEqualTo(base: 1, toCompareWith: 2), isTrue);
    });

    test("returns false when the base is greater", () {
      expect(ComparableUtility.isBaseLesserOrEqualTo(base: 3, toCompareWith: 2), isFalse);
    });

    test("accepts two equal values by default", () {
      expect(ComparableUtility.isBaseLesserOrEqualTo(base: 2, toCompareWith: 2), isTrue);
    });

    test("rejects two equal values when the comparison is strict", () {
      expect(
        ComparableUtility.isBaseLesserOrEqualTo(base: 2, toCompareWith: 2, testEquality: false),
        isFalse,
      );
    });
  });

  group("ComparableUtility.isBaseGreaterOrEqualTo", () {
    test("returns true when the base is greater", () {
      expect(ComparableUtility.isBaseGreaterOrEqualTo(base: 3, toCompareWith: 2), isTrue);
    });

    test("returns false when the base is smaller", () {
      expect(ComparableUtility.isBaseGreaterOrEqualTo(base: 1, toCompareWith: 2), isFalse);
    });

    test("accepts two equal values by default", () {
      expect(ComparableUtility.isBaseGreaterOrEqualTo(base: 2, toCompareWith: 2), isTrue);
    });

    test("rejects two equal values when the comparison is strict", () {
      expect(
        ComparableUtility.isBaseGreaterOrEqualTo(base: 2, toCompareWith: 2, testEquality: false),
        isFalse,
      );
    });
  });

  group("ComparableUtility.compareToBool", () {
    test("says two identical booleans are equal", () {
      expect(ComparableUtility.compareToBool(base: true, toCompareWith: true), 0);
      expect(ComparableUtility.compareToBool(base: false, toCompareWith: false), 0);
    });

    test("puts true after false by default", () {
      expect(ComparableUtility.compareToBool(base: true, toCompareWith: false), 1);
      expect(ComparableUtility.compareToBool(base: false, toCompareWith: true), -1);
    });

    test("puts true before false when it is asked to", () {
      expect(
        ComparableUtility.compareToBool(base: true, toCompareWith: false, trueIsBigger: false),
        -1,
      );
      expect(
        ComparableUtility.compareToBool(base: false, toCompareWith: true, trueIsBigger: false),
        1,
      );
    });
  });
}
