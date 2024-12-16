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
}
