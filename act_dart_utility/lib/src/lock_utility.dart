// Copyright (c) 2020. BMS Circuits

import 'dart:async';

/// Represents a lock
class LockEntity {
  Completer<Null> _lock;

  /// Default constructor
  LockEntity();

  /// This release the "lock" to let other access data
  void freeLock() {
    if (!isLocked) {
      // Nothing to free
      return;
    }

    _lock.complete();
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
  LockEntity _lockEntity;

  /// Class constructor
  LockUtility() : _lockEntity = LockEntity();

  /// Test if the lock is currently locked
  bool get isLocked => _lockEntity.isLocked;

  /// This only waits the lock to be freed and doesn't take the lock
  Future<void> wait() async {
    return waitAndLock(onlyWait: true);
  }

  /// This waits the lock to be freed and if [onlyWait] equals false take the
  /// lock.
  ///
  /// The method returns a [LockEntity] object which has to be kept in order to
  /// free the lock.
  ///
  /// If [onlyWait] equals to true, the method will return null
  Future<LockEntity> waitAndLock({bool onlyWait = false}) async {
    if (_lockEntity.isLocked) {
      await _lockEntity._lock.future;
    }

    if (onlyWait) {
      return null;
    }

    _lockEntity._lock = Completer<Null>();

    return _lockEntity;
  }
}
