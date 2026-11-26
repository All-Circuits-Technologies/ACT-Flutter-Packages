// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Utility class for [Duration] objects.
sealed class DurationUtility {
  /// This is the regular expression to parse a time zone offset string in the format of
  /// ±hh:mm, ±hhmm, ±hh, or Z (for UTC time zone)
  static final timeZoneOffsetRegexp = RegExp('(?:([+-])?([0-9]{1,2}):?([0-9]{1,2})?)|([zZ])');

  /// This is the index of the sign group in the time zone offset regular expression
  static const _timeZoneOffsetSignIndex = 1;

  /// This is the index of the hours group in the time zone offset regular expression
  static const _timeZoneOffsetHoursIndex = 2;

  /// This is the index of the minutes group in the time zone offset regular expression
  static const _timeZoneOffsetMinutesIndex = 3;

  /// This is the index of the UTC time zone group in the time zone offset regular expression
  static const _timeZoneOffsetZIndex = 4;

  /// This is the sign used in time zone offset string to indicate a negative offset
  static const _timeZoneOffsetMinusSign = '-';

  /// This is the factor to apply to hours and minutes when the time zone offset is positive
  static const _timeZoneOffsetPositiveFactor = 1;

  /// This is the factor to apply to hours and minutes when the time zone offset is negative
  static const _timeZoneOffsetNegativeFactor = -1;

  /// Convenient getter to get a formatted duration string as m:ss
  static String? formatMinSec(Duration? duration) {
    if (duration == null) {
      return null;
    }

    final minutes = duration.inMinutes.toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  /// Create a new [Duration] thanks to the given [seconds]
  ///
  /// This is useful for casting method which only expects one parameter
  static Duration? parseFromSeconds(int seconds) {
    if (seconds < 0) {
      return null;
    }

    return Duration(seconds: seconds);
  }

  /// Create a new [Duration] thanks to the given [milliseconds]
  ///
  /// This is useful for casting method which only expects one parameter
  static Duration? parseFromMilliseconds(int milliseconds) {
    if (milliseconds < 0) {
      return null;
    }

    return Duration(milliseconds: milliseconds);
  }

  /// Create a new [Duration] thanks to the given [timeZoneOffset] string in the format of ±hh:mm
  static Duration? parseFromTimeZoneOffset(String timeZoneOffset) {
    final match = timeZoneOffsetRegexp.firstMatch(timeZoneOffset);
    if (match == null) {
      return null;
    }

    final zGroup = match.group(_timeZoneOffsetZIndex);
    if (zGroup != null) {
      // The time zone offset is Z, which means UTC time zone
      return Duration.zero;
    }

    // From this point, we are sure that the time zone offset is in the format of ±hh:mm, ±hhmm, or
    // ±hh

    final sign = match.group(_timeZoneOffsetSignIndex);
    var signFactor = _timeZoneOffsetPositiveFactor;
    if (sign == _timeZoneOffsetMinusSign) {
      signFactor = _timeZoneOffsetNegativeFactor;
    }

    var hours = 0;
    var minutes = 0;

    final hoursGroup = match.group(_timeZoneOffsetHoursIndex);
    final minutesGroup = match.group(_timeZoneOffsetMinutesIndex);

    if (hoursGroup != null) {
      // Because the regex verify that the hours group is composed of 1 or 2 digits, we can be sure
      // that the parsing will not fail.
      // Therefore, we don't return null if the parsing fails
      hours = int.tryParse(hoursGroup) ?? 0;
    }

    if (minutesGroup != null) {
      // Because the regex verify that the minutes group is composed of 1 or 2 digits, we can be
      // sure that the parsing will not fail.
      // Therefore, we don't return null if the parsing fails
      minutes = int.tryParse(minutesGroup) ?? 0;
    }

    return Duration(hours: signFactor * hours, minutes: signFactor * minutes);
  }
}
