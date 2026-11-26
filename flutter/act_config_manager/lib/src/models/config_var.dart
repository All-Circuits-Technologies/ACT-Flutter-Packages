// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/models/abs_config_var.dart';

/// [ConfigVar] wraps a single config variable of type T, providing strongly-typed read helper.
///
/// To load a List\<T\> use the class `ConfigVarList`.
///
/// If the config variable isn't defined in the environment, [load] method returns null
class ConfigVar<T> extends AbsConfigVar<T> {
  /// Class constructor
  const ConfigVar(super.key);

  /// Load value from config variable.
  ///
  /// If the config variable isn't defined, the method will return null
  T? load() => configs.tryToGet<T>(key);
}
