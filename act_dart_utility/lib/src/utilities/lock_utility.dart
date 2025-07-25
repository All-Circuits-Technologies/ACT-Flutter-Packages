// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

/// Represents a lock
class LockEntity {
  /// This is the completer to use
  ///
  /// If null, there is nothing to wait
  Completer<void>? _lock;

  /// This is the future to wait the lock completion
  Future<void>? _future;

  /// Default constructor
  LockEntity();

  /// This release the "lock" to let other access data
  void freeLock() {
    if (!isLocked) {
      // Nothing to free
      return;
    }

    _lock?.complete();
    _lock = null;
  }

  /// Test if it's currently locked
  bool get isLocked => (_lock != null);
}

/// This class allows to manage a 'lock'
///
/// The class has two main methods: [wait] and [waitAndLock], those methods
/// allows to wait when a lock is set. Furthermore, the [waitAndLock] will get
/// the lock after the wait.
///
/// The lock utility works with the await mechanism
class LockUtility {
  /// The default maximum number of parallel requests that can be done at the same time before
  /// locking.
  static const defaultMaxParallelRequestsNb = 1;

  /// The maximum number of parallel requests that can be done at the same time before locking.
  final int maxParallelRequestsNb;

  /// This is the lock entity used to manage the lock
  final LockEntity _lockEntity;

  /// This is the current number of parallel requests that are currently running
  int _currentParallelNb;

  /// Class constructor
  LockUtility({
    this.maxParallelRequestsNb = defaultMaxParallelRequestsNb,
  })  : _currentParallelNb = 0,
        _lockEntity = LockEntity();

  /// Test if the lock is currently locked
  bool get isLocked => _lockEntity.isLocked;

  /// This only waits the lock to be freed and doesn't take the lock
  Future<void> wait() async {
    await waitAndOrLock(onlyWait: true);
  }

  /// This waits the lock to be freed and takes the lock.
  ///
  /// The method returns a [LockEntity] object which has to be kept in order to
  /// free the lock.
  Future<LockEntity> waitAndLock() async => (await waitAndOrLock())!;

  /// This method allows to encapsulate the locking before and after calling the given method
  /// [criticalSection].
  ///
  /// This is useful to be sure we never forget to free the lock
  Future<T> protectLock<T>(Future<T> Function() criticalSection, {bool onlyWait = false}) async {
    final entity = (await waitAndOrLock(onlyWait: onlyWait));
    try {
      return await criticalSection();
    } finally {
      entity?.freeLock();
    }
  }

  /// This waits the lock to be freed and if [onlyWait] equals false take the
  /// lock.
  ///
  /// The method returns a [LockEntity] object which has to be kept in order to
  /// free the lock.
  ///
  /// If [onlyWait] equals to true, the method will return null
  Future<LockEntity?> waitAndOrLock({bool onlyWait = false}) async {
    // If multiple elements wait the current completer, the first one which is released from lock
    // will create a new completer. Therefore, we have to test that the lock entity is no more
    // locked before continuing
    while (_lockEntity.isLocked) {
      await _lockEntity._future;
    }

    if (onlyWait) {
      return null;
    }

    ++_currentParallelNb;
    if (_currentParallelNb >= maxParallelRequestsNb) {
      final completer = Completer<void>();
      _lockEntity._lock = completer;
      // When the completer is ended we decrement the number of current parallel requests.
      // We do that before releasing the others
      _lockEntity._future = completer.future.then((value) => --_currentParallelNb);
    }

    return _lockEntity;
  }
}
