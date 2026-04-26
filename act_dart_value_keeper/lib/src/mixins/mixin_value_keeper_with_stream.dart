// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async' show StreamController;

import 'package:act_dart_value_keeper/src/models/value_keeper.dart';
import 'package:act_life_cycle/act_life_cycle.dart';

/// {@template act_dart_value_keeper.MixinValueKeeperWithStream}
/// Adds a stream to a ValueKeeper to notify the listeners when the value changes
///
/// Because it adds a stream, it also adds a [disposeLifeCycle] method to close the stream
/// controller when it's no longer needed. Therefore, you should call the [disposeLifeCycle] method
/// when you no longer need the model to avoid memory leaks.
/// {@endtemplate}
mixin MixinValueKeeperWithStream<S extends T, T>
    on BaseValueKeeper<S, T>, MixinWithLifeCycleDispose {
  /// This stream controller is used to notify the listeners when the value changes
  final StreamController<S> _valueStreamController = StreamController<S>.broadcast();

  /// {@template act_dart_value_keeper.MixinValueKeeperWithStream.emitUnchangedValue}
  /// Whether to emit the value in the stream even if it is the same as the current value.
  /// By default, it is false, which means that the stream will only emit a new value if it is
  /// different from the current value
  /// {@endtemplate}
  bool get emitUnchangedValue;

  /// This stream is used to notify the listeners when the value changes
  Stream<S> get valueStream => _valueStreamController.stream;

  /// {@macro act_dart_value_keeper.ValueKeeper.value.setter}
  @override
  set value(S newValue) {
    if (!emitUnchangedValue && newValue == value) {
      // Nothing to do
      return;
    }

    super.value = newValue;
    _valueStreamController.add(newValue);
  }

  /// {@macro act_life_cycle.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _valueStreamController.close();

    return super.disposeLifeCycle();
  }
}
