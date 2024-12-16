// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

/// Represents a lock
class LockEntity {
  Completer<void>? _lock;

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
  final LockEntity _lockEntity;

  /// Class constructor
  LockUtility() : _lockEntity = LockEntity();

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
  Future<T> protectLock<T>(Future<T> Function() criticalSection) async {
    final entity = (await waitAndOrLock())!;
    try {
      return await criticalSection();
    } finally {
      entity.freeLock();
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
    if (_lockEntity.isLocked) {
      await _lockEntity._lock?.future;
    }

    if (onlyWait) {
      return null;
    }

    _lockEntity._lock = Completer<void>();

    return _lockEntity;
  }
}
