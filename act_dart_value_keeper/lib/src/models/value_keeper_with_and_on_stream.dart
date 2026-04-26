// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async' show FutureOr, unawaited;

import 'package:act_dart_value_keeper/src/mixins/mixin_value_keeper_on_stream_update.dart';
import 'package:act_dart_value_keeper/src/mixins/mixin_value_keeper_with_stream.dart';
import 'package:act_dart_value_keeper/src/models/value_keeper.dart';
import 'package:act_life_cycle/act_life_cycle.dart';

/// {@macro act_dart_value_keeper.ValueTypeIsEqualToSetterValue}
///
/// {@macro act_dart_value_keeper.ValueKeeper}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperOnStreamUpdate}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperWithStream}
///
/// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
typedef ValueKeeperWithAndOnStream<T, Listened> = BaseValueKeeperWithAndOnStream<T, T, Listened>;

/// {@macro act_dart_value_keeper.ValueIsNullableButNotSetter}
///
/// {@macro act_dart_value_keeper.ValueKeeper}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperOnStreamUpdate}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperWithStream}
///
/// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
typedef ValueKeeperWithAndOnStreamAndNullInit<T, Listened> =
    BaseValueKeeperWithAndOnStream<T, T?, Listened>;

/// {@macro act_dart_value_keeper.ValueKeeper}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperOnStreamUpdate}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperWithStream}
///
/// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
///
/// {@macro act_dart_value_keeper.SMustBeCastableToT}
class BaseValueKeeperWithAndOnStream<S extends T, T, Listened> extends BaseValueKeeper<S, T>
    with
        MixinWithLifeCycleDispose,
        MixinValueKeeperWithStream<S, T>,
        MixinValueKeeperOnStreamUpdate<S, T, Listened> {
  /// {@macro act_dart_value_keeper.MixinValueKeeperOnStreamUpdate.parserCallback}
  @override
  final S? Function(Listened listenedValue) parserCallback;

  /// {@macro act_dart_value_keeper.MixinValueKeeperWithStream.emitUnchangedValue}
  @override
  final bool emitUnchangedValue;

  /// Class constructor
  BaseValueKeeperWithAndOnStream({
    required T initialValue,
    required this.parserCallback,
    required Stream<Listened> listenedStream,
    this.emitUnchangedValue = false,
    FutureOr<Listened?> Function()? initListenedValueGetter,
  }) : super(value: initialValue) {
    unawaited(
      initStreamListener(
        listenedStream: listenedStream,
        initListenedValueGetter: initListenedValueGetter,
      ),
    );
  }

  /// Alternative constructor to initialize the stream listener later. In this case, you should call
  /// the [initStreamListener] method to initialize the stream listener when the listened stream is
  /// available.
  BaseValueKeeperWithAndOnStream.lateInitStream({
    required T initialValue,
    required this.parserCallback,
    this.emitUnchangedValue = false,
  }) : super(value: initialValue);
}
