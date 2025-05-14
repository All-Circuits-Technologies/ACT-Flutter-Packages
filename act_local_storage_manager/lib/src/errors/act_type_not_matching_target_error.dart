// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This error is thrown when the [value] type is not equal to [T] type
class ActTypeNotMatchingTargetError<T> extends Error {
  /// This is the key of the local item
  final String key;

  /// This is the value got from storage
  final dynamic value;

  /// Class constructor
  ActTypeNotMatchingTargetError({
    required this.key,
    required this.value,
  });

  /// Display a representation of the error
  @override
  String toString() => "Key $key loaded as $value instead of type $T";
}
