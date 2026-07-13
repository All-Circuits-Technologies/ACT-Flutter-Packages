// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/src/blocs/async_init/async_init_events.dart';
import 'package:act_flutter_utility/src/blocs/bloc_for_mixin.dart';
import 'package:act_flutter_utility/src/blocs/bloc_state_for_mixin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This mixin is used to add asynchronous initialization to a bloc. It listens for the
/// [AsyncInitEvent] event and calls the [initAsyncBloc] method to perform asynchronous
/// initialization of the bloc.
///
/// If you want to trigger multiple times the asynchronous initialization of the bloc (for example
/// when the bloc is re-initialized or an error occurred in the init process), you can re-add the
/// [AsyncInitEvent] event yourself to the bloc.
mixin MixinAsyncInitBloc<S extends BlocStateForMixin<S>> on BlocForMixin<S> {
  /// {@macro act_flutter_utility.BlocForMixin.registerMixinEvents}
  @override
  void registerMixinEvents() {
    super.registerMixinEvents();

    on<AsyncInitEvent>(_onAsyncInitEvent);

    add(const AsyncInitEvent());
  }

  /// {@template act_flutter_utility.MixinAsyncInitBloc.initAsyncBloc}
  /// This method is called when the bloc is initialized. It is used to perform asynchronous
  /// initialization of the bloc.
  /// {@endtemplate}
  ///
  /// Call `super.initAsyncBloc()` first in the derived class method (unless otherwise specified by
  /// a derived class)
  @protected
  @mustCallSuper
  Future<void> initAsyncBloc({required Emitter<S> emit}) async {}

  /// Called when the [AsyncInitEvent] event is emitted. It calls the [initAsyncBloc] method to
  /// perform asynchronous initialization of the bloc.
  Future<void> _onAsyncInitEvent(AsyncInitEvent event, Emitter<S> emit) async {
    await initAsyncBloc(emit: emit);
  }
}
