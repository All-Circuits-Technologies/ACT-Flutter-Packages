// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/models/abs_config_var.dart';

/// [NotNullableConfigVar] wraps a single config variable of type T, providing strongly-typed
/// read helper.
///
/// To load a List\<T\> use the class `NotNullableConfigVarList`.
///
/// If the config variable isn't defined in the environment, [load] method returns [defaultValue]
class NotNullableConfigVar<T> extends AbsConfigVar<T> {
  /// The default value to use when nothing is retrieved from the config files.
  final T defaultValue;

  /// Class constructor
  /// If [defaultValue] isn't null, this value will be returned when null is retrieved from config
  /// files.
  const NotNullableConfigVar(
    super.key, {
    required this.defaultValue,
  });

  /// Load value from config variable.
  ///
  /// If the env variable isn't defined in the environment, the method will return the
  /// [defaultValue]
  T load() => configs.tryToGet<T>(key) ?? defaultValue;

  /// Class properties
  @override
  List<Object?> get props => [...super.props, defaultValue];
}
