// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Utility class for [Duration] objects.
class DurationUtility {
  /// Convenient getter to get a formatted duration string as m:ss
  static String? formatMinSec(Duration? duration) {
    if (duration == null) {
      return null;
    }

    final minutes = duration.inMinutes.toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }
}
