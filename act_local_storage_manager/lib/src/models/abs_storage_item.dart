// SPDX-FileCopyrightText: 2025 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_foundation/act_foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This abstract class is the base class for all storage items.
///
/// The item pushes on [updateStream] each value written through it, until it is disposed.
abstract class AbsStorageItem<T> extends Equatable with MixinWithLifeCycleDispose {
  /// The key used to access wrapped data inside SharedPreferences.
  final String key;

  /// The controller of [updateStream]
  final StreamController<T?> _updateStreamController;

  /// {@template act_local_storage_manager.AbsStorageItem.updateStream}
  /// The stream of the values written through this item.
  ///
  /// It pushes the value of each [store] and `null` on each [delete], even when the stored value
  /// does not change; use `distinct()` to listen to changes only.
  ///
  /// It only pushes the writes made through this item instance: a value stored through another
  /// item with the same key is not pushed.
  ///
  /// The stream is closed when the item is disposed: a value stored afterwards is still written,
  /// but no longer pushed.
  /// {@endtemplate}
  Stream<T?> get updateStream => _updateStreamController.stream;

  /// Class constructor
  AbsStorageItem({required this.key}) : _updateStreamController = StreamController.broadcast();

  /// {@template act_local_storage_manager.AbsStorageItem.load}
  /// Load value from storage.
  ///
  /// Returns null if value is not found or fails to be parsed.
  /// {@endtemplate}
  Future<T?> load();

  /// {@template act_local_storage_manager.AbsStorageItem.store}
  /// Store value to storage, and push it on [updateStream] when it has been stored.
  ///
  /// Returns false if a problem occurred.
  ///
  /// If [value] is null, we call [delete]
  /// {@endtemplate}
  @nonVirtual
  Future<bool> store(T? value) async {
    if (value == null) {
      await delete();
      return true;
    }

    final success = await storeImpl(value);
    if (success) {
      _emit(value);
    }

    return success;
  }

  /// {@template act_local_storage_manager.AbsStorageItem.delete}
  /// Remove value from storage, then push `null` on [updateStream].
  /// {@endtemplate}
  @nonVirtual
  Future<void> delete() async {
    await deleteImpl();
    _emit(null);
  }

  /// {@template act_local_storage_manager.AbsStorageItem.storeImpl}
  /// Write the [value] to the storage.
  ///
  /// Returns false if a problem occurred.
  /// {@endtemplate}
  @protected
  Future<bool> storeImpl(T value);

  /// {@template act_local_storage_manager.AbsStorageItem.deleteImpl}
  /// Remove the value from the storage.
  /// {@endtemplate}
  @protected
  Future<void> deleteImpl();

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  ///
  /// Closes [updateStream].
  @override
  Future<void> disposeLifeCycle() async {
    await _updateStreamController.close();
    return super.disposeLifeCycle();
  }

  /// Push [value] on [updateStream], unless the stream is closed
  void _emit(T? value) {
    if (!_updateStreamController.isClosed) {
      _updateStreamController.add(value);
    }
  }

  /// {@template act_local_storage_manager.AbsStorageItem.props}
  /// The storage item properties
  /// {@endtemplate}
  @override
  List<Object?> get props => [key];
}
