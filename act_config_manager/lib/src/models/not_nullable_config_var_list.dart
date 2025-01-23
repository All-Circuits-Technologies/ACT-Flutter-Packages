// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/models/abs_config_var.dart';

/// [NotNullableConfigVarList] wraps a single config variable of type List<T>, providing
/// strongly-typed read helper.
///
/// This class expects to find a List<T> element.
///
/// If the config variable isn't defined in the environment, [load] method returns [defaultValue]
class NotNullableConfigVarList<T> extends AbsConfigVar<T> {
  /// The default value to use when nothing is retrieved from the config files.
  final List<T> defaultValues;

  /// Class constructor
  /// If [defaultValues] isn't null, this value will be returned when null is retrieved from config
  /// files.
  const NotNullableConfigVarList(
    super.key, {
    required this.defaultValues,
  });

  /// Load value from config variable.
  ///
  /// If the env variable isn't defined in the environment, the method will return the
  /// [defaultValues]
  List<T> load() => configs.tryToGetList<T>(key) ?? defaultValues;

  /// Class properties
  @override
  List<Object?> get props => [...super.props, defaultValues];
}
