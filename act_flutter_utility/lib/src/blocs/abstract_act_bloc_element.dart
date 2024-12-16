// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

/// Helpful class to base the state and event on it
///
/// The fact to override [props] and create a default array allows to manage multiple mixins on
/// events and states
abstract class AbstractActBlocElement extends Equatable {
  @override
  @mustCallSuper
  List<Object?> get props => [];
}
