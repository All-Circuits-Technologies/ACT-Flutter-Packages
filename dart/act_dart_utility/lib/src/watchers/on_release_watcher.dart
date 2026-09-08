// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/src/watchers/shared_watcher.dart';

/// A watcher which trigger a callback when all its handlers are released (i.e. closed)
class OnReleaseWatcher extends SharedWatcher<OnReleaseHandler> {
  /// The callback to be triggered when all handlers are released
  FutureOr<void> Function() callback;

  /// Default class constructor
  OnReleaseWatcher({
    required this.callback,
    super.thresholdDuration,
  });

  /// {@macro act_dart_utility.SharedWatcher.generateHandler}
  @override
  OnReleaseHandler generateHandler() => OnReleaseHandler._(this);

  /// {@macro act_dart_utility.SharedWatcher.whenNoMoreHandler}
  @override
  Future<void> whenNoMoreHandler() async {
    await callback();
  }

  /// Supervises the execution of the [criticalSection] and ensures that the handler is properly
  /// closed after its execution.
  ///
  /// This method is useful to protect a critical section of code that needs to be monitored by the
  /// watcher.
  Future<T> supervise<T>(Future<T> Function() criticalSection) async {
    final handler = generateHandler();
    try {
      return await criticalSection();
    } finally {
      await handler.close();
    }
  }
}

/// A handler for the [OnReleaseWatcher]
class OnReleaseHandler extends SharedHandler {
  /// Default private class constructor
  OnReleaseHandler._(super.watcher);
}
