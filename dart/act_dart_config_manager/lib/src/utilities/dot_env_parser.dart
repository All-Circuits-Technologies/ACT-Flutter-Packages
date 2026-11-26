// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

/// This class contains useful methods to parse the content of a dot env file into a map of
/// environment variables.
sealed class DotEnvParser {
  /// This is the prefix a line can start with to export a variable.
  static const _exportPrefix = "export ";

  /// This is the character which separates the name of a variable from its value.
  static const _assignment = "=";

  /// This is the character which starts a comment line.
  static const _commentStart = "#";

  /// Parse [content] into a map of environment variables.
  ///
  /// Blank lines and lines which start with a [_commentStart] are ignored. A line is a name and a
  /// value separated by an [_assignment], with an optional [_exportPrefix]. The surrounding single
  /// or double quotes of a value are removed.
  static Map<String, String> parse(String content) {
    final result = <String, String>{};

    for (final rawLine in const LineSplitter().convert(content)) {
      final line = rawLine.trim();

      if (line.isEmpty || line.startsWith(_commentStart)) {
        continue;
      }

      final entry = line.startsWith(_exportPrefix)
          ? line.substring(_exportPrefix.length).trim()
          : line;

      final separatorIdx = entry.indexOf(_assignment);
      if (separatorIdx <= 0) {
        // A line without a name is ignored
        continue;
      }

      final key = entry.substring(0, separatorIdx).trim();
      final value = _unquote(entry.substring(separatorIdx + 1).trim());
      result[key] = value;
    }

    return result;
  }

  /// Remove the surrounding single or double quotes of [value], if it has any.
  static String _unquote(String value) {
    if (value.length < 2) {
      return value;
    }

    final first = value[0];
    final last = value[value.length - 1];

    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }

    return value;
  }
}
