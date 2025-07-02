// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/errors/act_config_null_value_error.dart';
import 'package:act_config_manager/src/models/abs_config_var.dart';
import 'package:act_global_manager/act_global_manager.dart';

/// [NotNullableConfigVar] wraps a single config variable of type T, providing strongly-typed
/// read helper.
///
/// To load a List\<T\> use the class `NotNullableConfigVarList`.
///
/// If the config variable isn't defined in the environment, [load] method returns [defaultValue]
class NotNullableConfigVar<T> extends AbsConfigVar<T> {
  /// The default value to use when nothing is retrieved from the config files.
  final T? defaultValue;

  /// Class constructor
  /// When null is retrieved from config, the [defaultValue] is returned.
  const NotNullableConfigVar(
    super.key, {
    required T this.defaultValue,
  });

  /// Class constructor
  /// When null is retried from config, the [ActConfigNullValueError] is thrown.
  const NotNullableConfigVar.crashIfNull(
    super.key,
  )   : defaultValue = null,
        super();

  /// Load value from config variable.
  ///
  /// If the config variable isn't defined in the environment, the method will return the
  /// [defaultValue] and if [defaultValue] is null, the [ActConfigNullValueError] is raised.
  T load() {
    final value = configs.tryToGet<T>(key) ?? defaultValue;
    if (value == null) {
      appLogger().e("The value of the config: $key, is null, we can't go further");
      throw ActConfigNullValueError(key: key);
    }

    return value;
  }

  /// Class properties
  @override
  List<Object?> get props => [...super.props, defaultValue];
}
