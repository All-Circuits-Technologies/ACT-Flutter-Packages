// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/services/config_singleton.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

/// [AbsConfigVar] wraps a single config variable of type T, providing strongly-typed read helper.
abstract class AbsConfigVar<T> extends Equatable {
  /// Gives access to the [ConfigSingleton] class instance for the derived class
  @protected
  ConfigSingleton get configs => ConfigSingleton.instance;

  /// The key used to access wrapped data inside config files.
  final String key;

  /// Create a config variable wrapper for key [key] of type T.
  const AbsConfigVar(this.key);

  @override
  List<Object?> get props => [key];
}
