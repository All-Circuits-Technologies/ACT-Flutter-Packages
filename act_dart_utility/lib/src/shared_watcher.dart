// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mutex/mutex.dart';

/// The watcher state
enum WatcherState {
  /// This means that the watcher has no handler attached
  sleep,

  /// This means that at least one handler is linked to the watcher
  awake,
}

/// The class is useful to only do actions if at least one element is using it
///
/// This allow to deactivate features when no one is using it
///
/// This is useful to manage shared resources
abstract class SharedWatcher<T extends SharedHandler> {
  /// If not null, when there is no more handler, the method will wait this duration before calling
  /// [whenNoMoreHandler] method.
  final Duration? thresholdDuration;

  /// This mutex protects the handler number modification, to be sure to not modify the value in
  /// parallel
  final Mutex _handlerMutex;

  /// When the threshold duration is given, this manage the timer linked.
  Timer? _thresholdTimer;

  /// The number of active handlers which still need the resource protected by this watcher
  int _handlerNb;

  /// Class constructor
  SharedWatcher({
    this.thresholdDuration,
  })  : _handlerMutex = Mutex(),
        _handlerNb = 0;

  /// Returns the current state of the watcher
  @protected
  WatcherState get state => (_handlerNb == 0) ? WatcherState.sleep : WatcherState.awake;

  /// Generate a handler to use with the watcher
  T generateHandler();

  /// Called when there is no handler and one is created
  @protected
  Future<void> atFirstHandler() async {}

  /// Called when the last handler is closed
  @protected
  Future<void> whenNoMoreHandler() async {}

  /// Call by a handler at it's creation
  Future<void> _takeOne() async => _handlerMutex.protect(() async {
        _handlerNb++;

        if (_handlerNb == 1) {
          if (_thresholdTimer != null) {
            // No need to call first handler because the whenNoMoreHandler method hasn't been called
            // yet
            _thresholdTimer?.cancel();
            _thresholdTimer = null;
          } else {
            await atFirstHandler();
          }
        }
      });

  /// Call by a handler when it's closed before it's destruction
  Future<void> _releaseOne() async => _handlerMutex.protect(() async {
        _handlerNb--;

        if (_handlerNb == 0 && _thresholdTimer == null) {
          if (thresholdDuration != null) {
            // We wait the threshold duration before calling whenNoMoreHandler
            _thresholdTimer = Timer(thresholdDuration!, _thresholdTimeout);
          } else {
            await whenNoMoreHandler();
          }
        }
      });

  /// Called when the threshold timeout is raised and the handler number is equal to zero
  Future<void> _thresholdTimeout() async => _handlerMutex.protect(() async {
        _thresholdTimer?.cancel();
        _thresholdTimer = null;

        if (_handlerNb == 0) {
          // We verify if the handler number is still equal to 0 ; which should be always the case
          // when we are here
          await whenNoMoreHandler();
        }
      });

  /// To call in order to stop properly all running tasks
  Future<void> close() async {}
}

/// Useful class attached to a watcher
///
/// This class is like a token which allows to stop features if the last of its
/// kind has been closed, or to start if at least one has been created.
///
/// When you do not more use the class instance, don't forget to call [close] method.
abstract class SharedHandler {
  final SharedWatcher _watcher;

  /// Get the watch linked to the handler
  @protected
  SharedWatcher get watcher => _watcher;

  /// Class constructor
  SharedHandler(SharedWatcher watcher) : _watcher = watcher {
    unawaited(_watcher._takeOne());
  }

  /// Call to close the [SharedHandler]
  @mustCallSuper
  Future<void> close() async {
    await _watcher._releaseOne();
  }
}
