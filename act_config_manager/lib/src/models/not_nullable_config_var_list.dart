// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/errors/act_config_null_value_error.dart';
import 'package:act_config_manager/src/models/abs_config_var.dart';
import 'package:act_global_manager/act_global_manager.dart';

/// [NotNullableConfigVarList] wraps a single config variable of type List\<T\>, providing
/// strongly-typed read helper.
///
/// This class expects to find a List\<T\> element.
///
/// If the config variable isn't defined in the environment, [load] method returns [defaultValues]
class NotNullableConfigVarList<T> extends AbsConfigVar<T> {
  /// The default value to use when nothing is retrieved from the config files.
  final List<T>? defaultValues;

  /// Class constructor
  /// When null is retrieved from config, the [defaultValues] is returned.
  const NotNullableConfigVarList(
    super.key, {
    required List<T> this.defaultValues,
  });

  /// Class constructor
  /// When null is retried from config, the [ActConfigNullValueError] is thrown.
  const NotNullableConfigVarList.crashIfNull(
    super.key,
  )   : defaultValues = null,
        super();

  /// Load value from config variable.
  ///
  /// If the config variable isn't defined in the environment, the method will return the
  /// [defaultValues] and if [defaultValues] is null, the [ActConfigNullValueError] is raised.
  List<T> load() {
    final values = configs.tryToGetList<T>(key) ?? defaultValues;
    if (values == null) {
      appLogger().e("The value of the config: $key, is null, we can't go further");
      throw ActConfigNullValueError(key: key);
    }

    return values;
  }

  /// Class properties
  @override
  List<Object?> get props => [...super.props, defaultValues];
}
