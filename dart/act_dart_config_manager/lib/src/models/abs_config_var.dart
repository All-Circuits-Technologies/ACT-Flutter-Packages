// SPDX-FileCopyrightText: 2024 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_config_manager/src/services/config_store.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

/// [AbsConfigVar] wraps a single config variable of type T, providing strongly-typed read helper.
abstract class AbsConfigVar<T> extends Equatable {
  /// Gives access to the [ConfigStore] class instance for the derived class
  @protected
  ConfigStore get configs => ConfigStore.instance;

  /// The key used to access wrapped data inside config files.
  final String key;

  /// Create a config variable wrapper for key [key] of type T.
  const AbsConfigVar(this.key);

  @override
  List<Object?> get props => [key];
}
