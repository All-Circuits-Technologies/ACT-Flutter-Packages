// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_value_keeper/src/mixins/mixin_value_keeper_with_stream.dart';
import 'package:act_dart_value_keeper/src/models/value_keeper.dart';
import 'package:act_life_cycle/act_life_cycle.dart';

/// {@macro act_dart_value_keeper.ValueTypeIsEqualToSetterValue}
///
/// {@macro act_dart_value_keeper.ValueKeeper}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperWithStream}
///
/// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
typedef ValueKeeperWithStream<T> = BaseValueKeeperWithStream<T, T>;

/// {@macro act_dart_value_keeper.ValueIsNullableButNotSetter}
///
/// {@macro act_dart_value_keeper.ValueKeeper}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperWithStream}
///
/// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
typedef ValueKeeperWithStreamAndNullInit<T> = BaseValueKeeperWithStream<T, T?>;

/// {@macro act_dart_value_keeper.ValueKeeper}
///
/// {@macro act_dart_value_keeper.MixinValueKeeperWithStream}
///
/// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
///
/// {@macro act_dart_value_keeper.SMustBeCastableToT}
class BaseValueKeeperWithStream<S extends T, T> extends BaseValueKeeper<S, T>
    with MixinWithLifeCycleDispose, MixinValueKeeperWithStream<S, T> {
  /// {@macro act_dart_value_keeper.MixinValueKeeperWithStream.emitUnchangedValue}
  @override
  final bool emitUnchangedValue;

  /// Class constructor
  BaseValueKeeperWithStream({required super.value, this.emitUnchangedValue = false});
}
