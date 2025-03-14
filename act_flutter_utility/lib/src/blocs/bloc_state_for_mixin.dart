// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This state is used by the [BlocForMixin]. When you want to create a mixin for a blox, use this
/// class as a base for your states.
abstract class BlocStateForMixin<S extends BlocStateForMixin<S>> extends Equatable {
  /// Mark the class as a const class.
  const BlocStateForMixin();

  /// {@template act_flutter_utility.BlocStateForMixin.copyWith}
  /// copyWith method.
  /// The derived mixin can force parameters to be required in the copyWith method of
  /// the derived state.
  /// {@endtemplate}
  @protected
  S copyWith();

  /// Empty [props] getter to force the [mustCallSuper] annotation.
  @override
  @mustCallSuper
  List<Object?> get props => [];
}
