// SPDX-FileCopyrightText: 2025 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/src/mixins/mixin_storage_singleton.dart';
import 'package:act_local_storage_manager/src/models/storage_write_event.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This abstract class is the base class for all storage items.
///
/// An item reads and writes the value of its [key] through the singleton of its [storage]: a
/// derived class only tells which storage it is.
abstract class AbsStorageItem<T> extends Equatable {
  /// The key used to access wrapped data inside SharedPreferences.
  final String key;

  /// {@template act_local_storage_manager.AbsStorageItem.storage}
  /// The storage singleton the item reads and writes its value through.
  /// {@endtemplate}
  @protected
  MixinStorageSingleton get storage;

  /// {@template act_local_storage_manager.AbsStorageItem.storageExtra}
  /// The extra information the item gives to its [storage] with each access.
  ///
  /// It is null, unless the storage of the item needs one.
  /// {@endtemplate}
  @protected
  Object? get storageExtra => null;

  /// {@template act_local_storage_manager.AbsStorageItem.updateStream}
  /// The stream of the values written under [key], as [load] would read them back.
  ///
  /// It pushes:
  ///
  /// - the value of each write, even when the stored value does not change; use `distinct()` to
  ///   listen to changes only,
  /// - `null` when the key is deleted, or when the storage is cleared,
  /// - `null` when the value written cannot be read as a T: written by another item of another
  ///   type, or refused by the parser of the item.
  ///
  /// It sees the writes made by every item of the same key and storage, but only those made
  /// through the storage singletons of this process.
  ///
  /// The storage singleton has to be created, by the initialization of its manager, before this
  /// getter is called.
  /// {@endtemplate}
  Stream<T?> get updateStream => storage.eventStream.where(_isAboutKey).map(_toItemValue);

  /// Class constructor
  const AbsStorageItem({required this.key});

  /// {@template act_local_storage_manager.AbsStorageItem.load}
  /// Load value from storage.
  ///
  /// Returns null if value is not found or fails to be parsed.
  /// {@endtemplate}
  Future<T?> load() async => storage.load<T>(key: key, extra: storageExtra);

  /// {@template act_local_storage_manager.AbsStorageItem.store}
  /// Store value to storage.
  ///
  /// Returns false if a problem occurred.
  ///
  /// If [value] is null, we call [delete]
  /// {@endtemplate}
  Future<bool> store(T? value) async =>
      storage.store<T>(key: key, value: value, extra: storageExtra);

  /// {@template act_local_storage_manager.AbsStorageItem.delete}
  /// Remove value from storage.
  /// {@endtemplate}
  Future<void> delete() async => storage.delete(key: key, extra: storageExtra);

  /// {@template act_local_storage_manager.AbsStorageItem.convertStoredValue}
  /// Convert the [value] the storage emitted for [key] to the type of the item.
  ///
  /// Returns null when the [value] cannot be read as a T.
  /// {@endtemplate}
  @protected
  T? convertStoredValue(Object? value) {
    if (value is! T) {
      return null;
    }

    return value;
  }

  /// Read the [event] as the value of the item it tells, `null` when the key has been deleted or
  /// the storage cleared
  T? _toItemValue(StorageWriteEvent event) => switch (event) {
    StorageClearedEvent() => null,
    StorageValueEvent(:final value) => (value == null) ? null : convertStoredValue(value),
  };

  /// Tell if the [event] is about the value of [key]
  bool _isAboutKey(StorageWriteEvent event) => switch (event) {
    StorageClearedEvent() => true,
    StorageValueEvent(key: final eventKey) => eventKey == key,
  };

  /// {@template act_local_storage_manager.AbsStorageItem.props}
  /// The storage item properties
  /// {@endtemplate}
  @override
  List<Object?> get props => [key];
}
