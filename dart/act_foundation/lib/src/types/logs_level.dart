// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This enum is used to define the level of logs in the package.
enum LogsLevel {
  /// The all level is used to log all messages.
  all(["all"]),

  /// The trace level is used to log the most detailed information.
  trace(["trace", "t"]),

  /// The debug level is used to log debug information.
  debug(["debug", "d"]),

  /// The info level is used to log information.
  info(["info", "i", "information"]),

  /// The warn level is used to log warnings.
  warn(["warn", "w", "warning"]),

  /// The error level is used to log errors.
  error(["error", "e"]),

  /// The fatal level is used to log fatal errors.
  ///
  /// This level is used to log errors that will cause the application to crash.
  fatal(["fatal", "f"]),

  /// The off level is used to disable all logs.
  off(["none", "n", "off"]);

  /// The list of string values that can be used to parse the enum from a string.
  final List<String> _strValues;

  /// Enum constructor.
  const LogsLevel(this._strValues);

  /// Parse the enum from a string.
  ///
  /// If the string is not a valid value, the function will return null.
  static LogsLevel? parseFromString(String value) {
    final lowerValue = value.toLowerCase();
    for (final level in LogsLevel.values) {
      if (level._strValues.contains(lowerValue)) {
        return level;
      }
    }

    return null;
  }
}
