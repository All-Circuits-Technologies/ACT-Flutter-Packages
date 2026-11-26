// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:math' show min;

import 'package:act_foundation/act_foundation.dart';

/// Contains utility methods linked to the usage of DateTime
sealed class DateTimeUtility {
  /// The constructed [DateTime] represents 1970-01-01T00:00:00Z (so in UTC)
  static final epoch = DateTime.utc(1970);

  /// Create a [DateTime] from [millisecondsSinceEpoch]. Returns null if the value given isn't in
  /// the expected range.
  ///
  /// This generates an UTC DateTime.
  ///
  /// This is useful for casting method which only expects one parameter
  static DateTime? fromMillisecondsSinceEpochUtc(
    int millisecondsSinceEpoch, {
    MixinActLogger? logger,
  }) => fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true, logger: logger);

  /// Create a [DateTime] from [millisecondsSinceEpoch]. Returns null if the value given isn't in
  /// the expected range.
  ///
  /// This is useful for casting method which only expects one parameter
  static DateTime? fromMillisecondsSinceEpoch(
    int millisecondsSinceEpoch, {
    bool isUtc = false,
    MixinActLogger? logger,
  }) {
    DateTime? dateTime;
    try {
      dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: isUtc);
    } catch (error) {
      logger?.w(
        "An error occurred when we tried to parse the dateTime from milliseconds since epoch: "
        "$millisecondsSinceEpoch, with isUtc: $isUtc",
        error,
      );
    }

    return dateTime;
  }

  /// Create a [DateTime] from [secondsSinceEpoch]. Returns null if the value given isn't in
  /// the expected range.
  ///
  /// This generates an UTC DateTime.
  ///
  /// This is useful for casting method which only expects one parameter
  static DateTime? fromSecondsSinceEpochUtc(int secondsSinceEpoch, {MixinActLogger? logger}) =>
      fromSecondsSinceEpoch(secondsSinceEpoch, isUtc: true, logger: logger);

  /// Create a [DateTime] from [secondsSinceEpoch]. Returns null if the value given isn't in
  /// the expected range.
  ///
  /// This is useful for casting method which only expects one parameter
  static DateTime? fromSecondsSinceEpoch(
    int secondsSinceEpoch, {
    bool isUtc = false,
    MixinActLogger? logger,
  }) {
    DateTime? dateTime;
    try {
      dateTime = DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000, isUtc: isUtc);
    } catch (error) {
      // An error occurred when tried to parse the dateTime from seconds since epoch
      logger?.w(
        "An error occurred when we tried to parse the dateTime from seconds since epoch: "
        "$secondsSinceEpoch, with isUtc: $isUtc",
        error,
      );
    }

    return dateTime;
  }

  /// Try to parse a formatted UTC string date to [DateTime]
  static DateTime? tryParseUtc(String formattedString) =>
      DateTime.tryParse(formattedString)?.copyWith(isUtc: true);

  /// This method allows to get the last moment of a particular day
  ///
  /// The method takes the year, month and day of the [date] given
  static DateTime getLastMomentOfADate(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999, 999);

  /// Get the current age from the [birthDate], the method compares with the data time now.
  ///
  /// It also transforms [birthDate] to UTC.
  ///
  /// This only returns the year. If we are at one day of the birth date, the year is not
  /// "validated".
  static int getCurrentAge(DateTime birthDate) {
    final now = DateTime.now().toUtc();
    final utcBirthDate = birthDate.toUtc();

    if (now.compareTo(utcBirthDate) < 0) {
      // We can't have a negative age
      return 0;
    }

    final year = now.year - utcBirthDate.year;
    final month = (now.month - utcBirthDate.month) / DateTime.monthsPerYear;
    var age = year + month;

    if (month == 0) {
      final days = (now.day - utcBirthDate.day);
      if (days < 0) {
        // In that case, we are at one day of the birthday
        --age;
      }
    }

    return age.truncate();
  }

  /// This method returns the number of whole calendar months elapsed from [from] to [to].
  ///
  /// Months do not all have the same length, therefore the count comes from the calendar and not
  /// from the elapsed duration: a month is only counted once the day of the month and the time of
  /// day of [from] have been reached again. When that day of the month does not exist in the
  /// arrival month, the last day of that month stands in for it: from the 31st of January, the
  /// 28th of February is a whole month.
  ///
  /// The count is signed and the method is antisymmetric: swapping [from] and [to] only changes
  /// the sign of the result. It is zero for two equal date times, and for any interval shorter
  /// than a whole month in either direction. Callers which cannot make sense of a negative or
  /// null count are expected to clamp the result themselves.
  ///
  /// [to] is compared in the time zone of [from]: an UTC [from] compares UTC calendar fields, a
  /// local one compares local calendar fields.
  static int wholeMonthsBetween({required DateTime from, required DateTime to}) {
    final target = from.isUtc ? to.toUtc() : to.toLocal();

    final isReversed = target.isBefore(from);
    final start = isReversed ? target : from;
    final end = isReversed ? from : target;

    // The difference of the calendar fields overshoots by at most one month: the last month is
    // only whole once the anniversary of [start] has been reached.
    var months = ((end.year - start.year) * DateTime.monthsPerYear) + end.month - start.month;

    if (addMonths(start, months).isAfter(end)) {
      --months;
    }

    return isReversed ? -months : months;
  }

  /// This method adds [months] to [date]; [months] may be negative.
  ///
  /// The day of the month is clamped to the length of the arrival month: adding one month to the
  /// 31st of January returns the 28th of February, or the 29th on a leap year. The time of day and
  /// the time zone of [date] are kept.
  static DateTime addMonths(DateTime date, int months) {
    // The index of the month in the year, from zero, once the months have been added. It may be
    // negative, therefore the year offset has to be a floored division and not a truncated one.
    final monthIndex = date.month - 1 + months;

    final monthInYear = monthIndex % DateTime.monthsPerYear;
    final year = date.year + ((monthIndex - monthInYear) ~/ DateTime.monthsPerYear);
    final month = monthInYear + 1;

    // Day zero of the next month is the last day of the arrival month.
    final lastDayOfMonth = date.copyWith(year: year, month: month + 1, day: 0).day;

    return date.copyWith(year: year, month: month, day: min(date.day, lastDayOfMonth));
  }
}
