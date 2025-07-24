// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Contains utility methods linked to the usage of DateTime
abstract class DateTimeUtility {
  /// The constructed [DateTime] represents 1970-01-01T00:00:00Z (so in UTC)
  static final epoch = DateTime.utc(1970);

  /// Create a [DateTime] from [millisecondsSinceEpoch]. Returns null if the value given isn't in
  /// the expected range.
  ///
  /// This generates an UTC DateTime.
  ///
  /// This is useful for casting method which only expects one parameter
  static DateTime? fromMillisecondsSinceEpochUtc(int millisecondsSinceEpoch) =>
      fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: true);

  /// Create a [DateTime] from [millisecondsSinceEpoch]. Returns null if the value given isn't in
  /// the expected range.
  ///
  /// This is useful for casting method which only expects one parameter
  static DateTime? fromMillisecondsSinceEpoch(int millisecondsSinceEpoch, {bool isUtc = false}) {
    DateTime? dateTime;
    try {
      dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch, isUtc: isUtc);
    } catch (error) {
      // An error occurred when tried to parse the dateTime from milliseconds since epoch
    }

    return dateTime;
  }

  /// Create a [DateTime] from [secondsSinceEpoch]. Returns null if the value given isn't in
  /// the expected range.
  ///
  /// This generates an UTC DateTime.
  ///
  /// This is useful for casting method which only expects one parameter
  static DateTime? fromSecondsSinceEpochUtc(int secondsSinceEpoch) =>
      fromSecondsSinceEpoch(secondsSinceEpoch, isUtc: true);

  /// Create a [DateTime] from [secondsSinceEpoch]. Returns null if the value given isn't in
  /// the expected range.
  ///
  /// This is useful for casting method which only expects one parameter
  static DateTime? fromSecondsSinceEpoch(int secondsSinceEpoch, {bool isUtc = false}) {
    DateTime? dateTime;
    try {
      dateTime = DateTime.fromMillisecondsSinceEpoch(secondsSinceEpoch * 1000, isUtc: isUtc);
    } catch (error) {
      // An error occurred when tried to parse the dateTime from seconds since epoch
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
}
