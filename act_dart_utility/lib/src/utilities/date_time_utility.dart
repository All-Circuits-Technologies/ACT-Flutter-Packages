// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Contains utility methods linked to the usage of DateTime
abstract class DateTimeUtility {
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
