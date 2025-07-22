// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter/foundation.dart' show protected;

/// This mixin adds a string value to the enum which can be used to parse the enum.
///
/// Because the value can be used to parse the enum, it must be unique for the enum.
mixin MixinStringValueType on Enum {
  /// {@template act_dart_utility.MixinStringValueType.stringValueOverride}
  /// Optional unique string value override
  ///
  /// See [stringValue]
  /// {@endtemplate}
  @protected
  String? get stringValueOverride => null;

  /// Get enum unique string value
  ///
  /// Returns [name], except if subclass overrides [stringValueOverride] with a non-null value.
  String get stringValue => stringValueOverride ?? name;

  /// Try to find an enum value among [values], given its String [value].
  ///
  /// Returns the enum value if found, null otherwise.
  ///
  /// Typically, you want [values] to contain all the values the Enum can have,
  /// and you are advised to implement a `parseFromStringValue` this way in your subclass:
  /// ```dart
  /// static T? parseFromStringValue(String? value) =>
  ///     MixinDbType.tryToParseFromStringValue(value, values);
  /// ```
  static T? tryToParseFromStringValue<T extends MixinStringValueType>({
    required String? value,
    required List<T> values,
  }) {
    if (value == null) {
      return null;
    }

    final lowercaseJsonValue = value.toLowerCase();
    for (final enumValue in values) {
      if (enumValue.stringValue.toLowerCase() == lowercaseJsonValue) {
        return enumValue;
      }
    }

    return null;
  }
}
