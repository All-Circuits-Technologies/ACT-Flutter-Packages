// SPDX-FileCopyrightText: 2025 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_local_storage_manager/src/models/storage_write_event.dart';
import 'package:flutter/foundation.dart';

/// This is the mixin on the storage singleton
///
/// The singleton emits a [StorageWriteEvent] on [eventStream] each time it is written to.
mixin MixinStorageSingleton on AbsWithLifeCycle {
  /// The controller of [eventStream]
  final StreamController<StorageWriteEvent> _eventCtrl =
      StreamController<StorageWriteEvent>.broadcast();

  /// {@template act_local_storage_manager.MixinStorageSingleton.eventStream}
  /// The stream of the writes made to the storage.
  ///
  /// It emits a [StorageValueEvent] for each [store] and each [delete], even when the stored value
  /// does not change, and a [StorageClearedEvent] when [deleteAll] clears the storage. It only
  /// emits the writes made through this singleton, in this process.
  /// {@endtemplate}
  Stream<StorageWriteEvent> get eventStream => _eventCtrl.stream;

  /// {@template act_local_storage_manager.MixinStorageSingleton.load}
  /// Load value from storage.
  ///
  /// Returns null if preference item is not found (if it has never been stored
  /// or if it has been deleted meanwhile).
  ///
  /// If T isn't known, this will raise an [UnsupportedError] error.
  /// {@endtemplate}
  Future<T?> load<T>({required String key, Object? extra});

  /// {@template act_local_storage_manager.MixinStorageSingleton.store}
  /// Store value to underlying storage, then emit it on [eventStream] if it has been stored.
  ///
  /// If T isn't known, this will raise an [UnsupportedError] error.
  ///
  /// If the value is null, we [delete] the key.
  /// {@endtemplate}
  @nonVirtual
  Future<bool> store<T>({required String key, required T? value, Object? extra}) async {
    if (value == null) {
      await delete(key: key, extra: extra);
      return true;
    }

    final success = await storeImpl<T>(key: key, value: value, extra: extra);
    if (success) {
      _emit(StorageValueEvent(key: key, value: value));
    }

    return success;
  }

  /// {@template act_local_storage_manager.MixinStorageSingleton.delete}
  /// Remove value from storage, then emit a null value on [eventStream].
  ///
  /// This is actually equivalent to storing a null value.
  /// {@endtemplate}
  @nonVirtual
  Future<void> delete({required String key, Object? extra}) async {
    await deleteImpl(key: key, extra: extra);
    _emit(StorageValueEvent(key: key, value: null));
  }

  /// {@template act_local_storage_manager.MixinStorageSingleton.deleteAll}
  /// Remove all the value from storage, then emit a [StorageClearedEvent] on [eventStream] if the
  /// storage has been cleared.
  /// {@endtemplate}
  @nonVirtual
  Future<void> deleteAll({Object? extra}) async {
    final cleared = await deleteAllImpl(extra: extra);
    if (cleared) {
      _emit(const StorageClearedEvent());
    }
  }

  /// {@template act_local_storage_manager.MixinStorageSingleton.storeImpl}
  /// Write the [value] to the underlying storage.
  ///
  /// Returns false if a problem occurred.
  ///
  /// If T isn't known, this will raise an [UnsupportedError] error.
  /// {@endtemplate}
  @protected
  Future<bool> storeImpl<T>({required String key, required T value, Object? extra});

  /// {@template act_local_storage_manager.MixinStorageSingleton.deleteImpl}
  /// Remove the value of [key] from the underlying storage.
  /// {@endtemplate}
  @protected
  Future<void> deleteImpl({required String key, Object? extra});

  /// {@template act_local_storage_manager.MixinStorageSingleton.deleteAllImpl}
  /// Remove all the values from the underlying storage.
  ///
  /// Returns false if the storage has not been cleared.
  /// {@endtemplate}
  @protected
  Future<bool> deleteAllImpl({Object? extra});

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  ///
  /// Closes [eventStream].
  @override
  Future<void> disposeLifeCycle() async {
    await _eventCtrl.close();
    return super.disposeLifeCycle();
  }

  /// Emit [event] on [eventStream], unless the stream is closed
  void _emit(StorageWriteEvent event) {
    if (!_eventCtrl.isClosed) {
      _eventCtrl.add(event);
    }
  }
}
