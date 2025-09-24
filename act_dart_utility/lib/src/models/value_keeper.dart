// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// {@template act_dart_utility.ValueKeeper}
/// This object is used to keep a value inside
///
/// This is useful, when you want to update a value in a final object, to read the value at a
/// particular moment
/// {@endtemplate}
class ValueKeeper<T> {
  /// The value to keep
  T? _value;

  /// {@template act_dart_utility.ValueKeeper.value.getter}
  /// Getter to the value to keep
  /// {@endtemplate}
  // Even if in this class the getter and setter aren't necessary we keep them for the derived class
  // ignore: unnecessary_getters_setters
  T? get value => _value;

  /// {@template act_dart_utility.ValueKeeper.value.setter}
  /// Setter of the value to keep
  /// {@endtemplate}
  set value(T? newValue) => _value = newValue;

  /// Class constructor
  ValueKeeper({T? value}) : _value = value;
}
