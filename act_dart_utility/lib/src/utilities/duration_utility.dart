// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Utility class for [Duration] objects.
sealed class DurationUtility {
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
}
