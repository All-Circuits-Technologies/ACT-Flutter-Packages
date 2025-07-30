// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This object is used to keep a value inside
///
/// This is useful, when you want to update a value in a final object, to read the value at a
/// particular moment
class ValueKeeper<T> {
  /// The value to keep
  T? value;

  /// Class constructor
  ValueKeeper({this.value});
}
