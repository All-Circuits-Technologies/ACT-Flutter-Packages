// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This event is used by the `BlocForMixin`. When you want to create a mixin for a blox, use this
/// event as the base class for your events.
abstract class BlocEventForMixin extends Equatable {
  /// Class constructor.
  const BlocEventForMixin();

  /// {@template act_flutter_utility.BlocEventForMixin.props}
  /// Force the implementation of the props getter.
  /// {@endtemplate}
  @override
  @mustCallSuper
  List<Object?> get props => [];
}
