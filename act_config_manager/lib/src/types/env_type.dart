// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This is the environment type which can be used in the config mapping file
enum EnvType {
  string(["string", "str"]),
  bool(["bool", "boolean"]),
  number(["num", "number", "int", "integer", "decimal", "float"]),
  yaml(["yaml", "json", "yml"]);

  /// This is the value which can be used in `__format` attribute of the variable to describe the
  /// environment type
  final List<String> _couldBeParsedWith;

  /// Enum constructor
  const EnvType(this._couldBeParsedWith);

  /// Parse the env type from string.
  ///
  /// If the [value] isn't known, the method returns null
  static EnvType? parseFromString(String value) {
    final lowCaseValue = value.toLowerCase();

    for (final value in EnvType.values) {
      for (final beParsedWith in value._couldBeParsedWith) {
        if (beParsedWith.contains(lowCaseValue)) {
          return value;
        }
      }
    }

    return null;
  }
}
