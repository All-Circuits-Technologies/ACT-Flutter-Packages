// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This mixin adds a value to the enum which can be used to parse the enum.
///
/// Because the value can be used to parse the enum, it must be unique for the enum.
mixin MixinUniqueValueType<M> on Enum {
  /// {@template act_dart_utility.MixinUniqueValueType.uniqueValue}
  /// Get enum unique value
  /// {@endtemplate}
  M get uniqueValue;

  /// Try to find an enum value among [values], given its [value].
  ///
  /// Returns the enum value if found, null otherwise.
  ///
  /// Typically, you want [values] to contain all the values the Enum can have,
  /// and you are advised to implement a `parseFromValue` this way in your subclass:
  /// ```dart
  /// static T? parseFromValue(M? value) =>
  ///     MixinDbType.tryToParseFromUniqueValue<M, T>(value, values);
  /// ```
  static T? tryToParseFromUniqueValue<M, T extends MixinUniqueValueType<M>>({
    required M? value,
    required List<T> values,
  }) {
    if (value == null) {
      return null;
    }

    for (final enumValue in values) {
      if (enumValue.uniqueValue == value) {
        return enumValue;
      }
    }

    return null;
  }
}
