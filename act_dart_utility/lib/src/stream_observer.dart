// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:flutter/foundation.dart';

/// [StreamObserver] is an abstract class that listens to a [Stream] and checks if the value
/// received on the stream is valid or not. The validity of the value is published on a [Stream].
abstract class StreamObserver<T> {
  /// Subscription to the [Stream] we listen to.
  late final StreamSubscription _subscription;

  /// True if the value we listen to is valid, false otherwise.
  late bool _isValid;

  /// Strem controller to publish the consent validity.
  final StreamController<bool> _streamController;

  /// Getter for the [_isValid] property.
  bool get isValid => _isValid;

  /// Getter for the [_streamController] stream property.
  Stream<bool> get stream => _streamController.stream;

  /// Class constructor.
  StreamObserver({
    required Stream<T> stream,
    required T Function() get,
  }) : _streamController = StreamController<bool>.broadcast() {
    _subscription = stream.listen(_onData);
    _isValid = isNewValueValid(get());
  }

  /// Method called when a new value is received on the stream we listen to.
  Future<void> _onData(T value) async {
    final previousIsValid = _isValid;

    _isValid = isNewValueValid(value);

    // Nothing to do if the value didn't change
    if (_isValid == previousIsValid) {
      return;
    }

    _streamController.add(_isValid);
  }

  /// Implement this method in the derived class to check if the value received on the stream is
  /// valid or not.
  @protected
  bool isNewValueValid(T value);

  /// Cancel the subscription to the stream and close the stream controller.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _streamController.close();
  }
}
