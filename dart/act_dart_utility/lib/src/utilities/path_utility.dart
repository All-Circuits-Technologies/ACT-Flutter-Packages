// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:path/path.dart' as p;

/// Contains utility methods to manage paths and extends the functionality of path operations.
sealed class PathUtility {
  /// Get the extension of the [path] without the dot.
  ///
  /// If there is no extension, an empty string is returned.
  ///
  /// The [level] parameter specifies the number of extensions to return.
  /// For example, for a file named "archive.tar.gz":
  /// - level 1 will return "gz"
  /// - level 2 will return "tar.gz"
  static String extensionWithoutDot(String path, [int level = 1]) {
    final ext = p.extension(path, level);
    if (ext.isEmpty) {
      return ext;
    }
    return ext.substring(1);
  }
}
