// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This utility class provides methods to compare comparable objects
sealed class ComparableUtility {
  /// This is the default value returned by the compare methods to signify that the first value is
  /// bigger than the second value.
  static const defaultBiggerValue = 1;

  /// This is the default value returned by the compare methods to signify that the first value is
  /// smaller than the second value.
  static const defaultSmallerValue = -1;

  /// This is the default value returned by the compare methods to signify that the two values are
  /// equal.
  static const defaultEqualValue = 0;

  /// This method allows to compare two nullable comparable objects.
  ///
  /// If the objects are null, it uses the [defaultValue] to compare them.
  static int compareToWithDefault<Y extends Comparable<Y>>({
    required Y? base,
    required Y? toCompareWith,
    required Y defaultValue,
  }) => (base ?? defaultValue).compareTo(toCompareWith ?? defaultValue);

  /// This method allows to compare two nullable comparable objects.
  ///
  /// If one of the values is null, the [nullIsBigger] parameter allows to choose if the null value
  /// is bigger than the non-null value.
  /// If both values are null, the method will return [defaultEqualValue].
  /// If both values are non-null, the method will return the result of the compareTo method.
  ///
  /// When possible, prefer using the [compareToWithDefault] method instead of this method, it will
  /// return comparable and relevant values instead of only -1, 0 and 1.
  static int compareToNullable<Y extends Comparable<Y>>({
    required Y? base,
    required Y? toCompareWith,
    bool nullIsBigger = false,
  }) {
    if (base == null && toCompareWith == null) {
      return defaultEqualValue;
    }

    if (base == null) {
      return nullIsBigger ? defaultBiggerValue : defaultSmallerValue;
    }

    if (toCompareWith == null) {
      return nullIsBigger ? defaultSmallerValue : defaultBiggerValue;
    }

    return base.compareTo(toCompareWith);
  }

  /// Compares the given values to know if [base] value is strictly lesser than [toCompareWith]
  /// value (in that case, the method returns true).
  ///
  /// If [testEquality] is equals to true, it also returns true if values are equals.
  ///
  /// Uses `compareTo` method.
  static bool isBaseLesserOrEqualTo<Y extends Comparable<Y>>({
    required Y base,
    required Y toCompareWith,
    bool testEquality = true,
  }) {
    final comparison = base.compareTo(toCompareWith);
    return comparison < 0 || testEquality && comparison == 0;
  }

  /// Compares the given values to know if [base] value is strictly greather than
  /// [toCompareWith] value (in that case, the method returns true).
  ///
  /// If [testEquality] is equals to true, it also returns true if values are equals.
  ///
  /// Uses `compareTo` method.
  static bool isBaseGreaterOrEqualTo<Y extends Comparable<Y>>({
    required Y base,
    required Y toCompareWith,
    bool testEquality = true,
  }) {
    final comparison = base.compareTo(toCompareWith);
    return comparison > 0 || testEquality && comparison == 0;
  }

  /// This method allows to compare two boolean
  ///
  /// The [trueIsBigger] parameter allows to choose if the true value is bigger than the false value
  static int compareToBool({
    required bool base,
    required bool toCompareWith,
    bool trueIsBigger = true,
  }) {
    if (base == toCompareWith) {
      return 0;
    }

    if ((base && trueIsBigger) || (!base && !trueIsBigger)) {
      return 1;
    }

    return -1;
  }
}
