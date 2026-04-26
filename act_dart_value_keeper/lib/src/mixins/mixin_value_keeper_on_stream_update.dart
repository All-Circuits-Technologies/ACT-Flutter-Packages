// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async' show FutureOr, StreamSubscription;

import 'package:act_dart_value_keeper/src/models/value_keeper.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter/foundation.dart';

/// {@template act_dart_value_keeper.MixinValueKeeperOnStreamUpdate}
/// This mixin should be used on ValueKeepers that need to update their value based on a listened
/// stream.
/// {@endtemplate}
mixin MixinValueKeeperOnStreamUpdate<S extends T, T, Listened>
    on BaseValueKeeper<S, T>, MixinWithLifeCycleDispose {
  /// This stream subscription is used to listen to the listened stream, and update the value keeper value
  StreamSubscription<Listened>? _listenedStreamSubscription;

  /// {@template act_dart_value_keeper.MixinValueKeeperOnStreamUpdate.parserCallback}
  /// This callback is called when the listened stream emits a new value, to parse it and update
  /// the value of the value keeper.
  ///
  /// It should return null if the listened value cannot be parsed, or if it should not update the
  /// value keeper value.
  /// {@endtemplate}
  S? Function(Listened listenedValue) get parserCallback;

  /// {@template act_dart_value_keeper.MixinValueKeeperOnStreamUpdate.initStreamListener}
  /// This method should be called to initialize the stream listener, and optionally set the initial
  /// value of the value keeper based on the listened stream.
  /// {@endtemplate}
  Future<void> initStreamListener({
    required Stream<Listened> listenedStream,
    FutureOr<Listened?> Function()? initListenedValueGetter,
  }) async {
    await _listenedStreamSubscription?.cancel();
    _listenedStreamSubscription = listenedStream.listen(onStreamUpdate);

    final initListenedValue = await initListenedValueGetter?.call();
    if (initListenedValue == null) {
      // Nothing to do
      return;
    }

    onStreamUpdate(initListenedValue);
  }

  /// Called when the listened stream emits a new value, to update the value keeper value based on
  /// the listened value.
  @protected
  void onStreamUpdate(Listened listenedValue) {
    final parsedValue = parserCallback(listenedValue);
    if (parsedValue == null) {
      // Nothing to do
      return;
    }

    value = parsedValue;
  }

  /// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _listenedStreamSubscription?.cancel();

    return super.disposeLifeCycle();
  }
}
