// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// {@template act_dart_value_keeper.ValueTypeIsEqualToSetterValue}
/// This typedef is used when the setter value is the same as the class value, which is the most
/// common case. It is just a shorthand to avoid writing the same type twice.
/// {@endtemplate}
typedef ValueKeeper<T> = BaseValueKeeper<T, T>;

/// {@template act_dart_value_keeper.ValueIsNullableButNotSetter}
/// This typedef is used when the value is nullable, but the setter value is not. This can be useful
/// when you want to create a ValueKeeper with no initial value, but you want to be able to set
/// non-nullable values later. In this case, the value will be null until the first time the setter
/// is called.
/// {@endtemplate}
typedef ValueKeeperWithNullInit<T> = BaseValueKeeper<T, T?>;

/// {@template act_dart_value_keeper.ValueKeeper}
/// This object is used to keep a value inside
///
/// This is useful, when you want to update a value in a final object, to read the value at a
/// particular moment.
/// {@endtemplate}
///
/// {@template act_dart_value_keeper.SMustBeCastableToT}
/// Here we expect the S type to be castable to T
///
/// Note that this class is not designed to be used directly, prefer to use linked typedefs, or to
/// create your own typedef which respect cast expectation between S and T.
/// {@endtemplate}
class BaseValueKeeper<S extends T, T> {
  /// The value to keep
  T _value;

  /// {@template act_dart_value_keeper.ValueKeeper.value.getter}
  /// Getter to the value to keep
  /// {@endtemplate}
  // We want to keep the getter to be able to override it in derived classes
  // ignore: unnecessary_getters_setters
  T get value => _value;

  /// {@template act_dart_value_keeper.ValueKeeper.value.setter}
  /// Setter of the value to keep
  /// {@endtemplate}
  // We want to keep the setter to be able to override it in derived classes
  // ignore: unnecessary_getters_setters
  set value(S newValue) => _value = newValue;

  /// Class constructor
  BaseValueKeeper({required T value}) : _value = value;

  /// Class constructor to create a ValueKeeper from a setter value, which can be useful when you
  /// want to use the ValueKeeper in a setter callback
  BaseValueKeeper.fromSetterValue({required S value}) : _value = value;
}
