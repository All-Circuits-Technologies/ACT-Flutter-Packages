// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/blocs/bloc_event_for_mixin.dart';
import 'package:act_flutter_utility/src/blocs/bloc_state_for_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This bloc is usefull when you want to create a bloc with mixin.
abstract class BlocForMixin<S extends BlocStateForMixin<S>> extends Bloc<BlocEventForMixin, S> {
  /// Constructor for the bloc.
  BlocForMixin(super.initialState) {
    registerMixinEvents();
  }

  /// {@template act_flutter_utility.BlocForMixin.registerMixinEvents}
  /// Override this method in your mixin to register the events (on\<EventX\>(_onEventX)) in the
  /// bloc.
  /// We provide an empty definition to allow the "@mustCallSuper" annotation and make sure
  /// the method can be called in the constructor.
  /// {@endtemplate}
  @mustCallSuper
  void registerMixinEvents() {}
}
