// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/models/abs_config_var.dart';

/// [ConfigVarList] wraps a single config variable of type List\<T\>, providing strongly-typed read
/// helper.
///
/// This class expects to find a List\<T\> element.
///
/// If the config variable isn't defined in the environment, [load] method returns null
class ConfigVarList<T> extends AbsConfigVar<T> {
  /// Class constructor
  const ConfigVarList(super.key);

  /// Load value from config variable.
  ///
  /// If the config variable isn't defined, the method will return null
  List<T>? load() => configs.tryToGetList<T>(key);
}
