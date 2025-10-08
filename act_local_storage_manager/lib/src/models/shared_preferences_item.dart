// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_local_storage_manager/src/models/abs_storage_item.dart';
import 'package:act_local_storage_manager/src/services/properties_singleton.dart';
import 'package:flutter/foundation.dart';

/// [SharedPreferencesItem] wraps a single property of type T,
/// providing strongly-typed load and store helpers.
///
/// Such data is stored in plain text, hence should not be secret.
/// For secrets, please see `SecretItem`.
///
/// {@macro act_local_storage_manager.PropertiesSingleton.supportedTypes}
class SharedPreferencesItem<T> extends AbsStorageItem<T> {
  final StreamController<T> _updateStreamController;

  /// With this stream you can subscribe to data update
  Stream get updateStream => _updateStreamController.stream;

  /// Create a SharedPreferences wrapper for key [key] of type T.
  ///
  /// Only `AbstractPropertiesManager` creates instances of this helper class.
  /// Other actors uses them.
  SharedPreferencesItem(String key)
      : _updateStreamController = StreamController.broadcast(),
        super(key: key);

  /// {@macro act_local_storage_manager.AbsStorageItem.load}
  @override
  Future<T?> load() async => PropertiesSingleton.instance.load<T>(key: key);

  /// {@macro act_local_storage_manager.AbsStorageItem.store}
  @override
  Future<bool> store(T? value) async {
    final success = await PropertiesSingleton.instance.store<T>(key: key, value: value);
    if (!success) {
      return false;
    }

    emitEventIfNecessary(value);
    return true;
  }

  /// {@macro act_local_storage_manager.AbsStorageItem.delete}
  @override
  Future<void> delete() async => PropertiesSingleton.instance.delete(key: key);

  /// Emit event on the [updateStream] if the value isn't null
  @protected
  void emitEventIfNecessary(T? value) {
    if (!_updateStreamController.isClosed && value != null) {
      _updateStreamController.add(value);
    }
  }
}
