// SPDX-FileCopyrightText: 2025 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/src/models/abs_storage_item.dart';
import 'package:act_local_storage_manager/src/services/properties_singleton.dart';

/// [SharedPreferencesItem] wraps a single property of type T,
/// providing strongly-typed load and store helpers.
///
/// Such data is stored in plain text, hence should not be secret.
/// For secrets, please see `SecretItem`.
///
/// {@macro act_local_storage_manager.PropertiesSingleton.supportedTypes}
class SharedPreferencesItem<T> extends AbsStorageItem<T> {
  /// Create a SharedPreferences wrapper for key [key] of type T.
  ///
  /// Only `AbstractPropertiesManager` creates instances of this helper class.
  /// Other actors uses them.
  SharedPreferencesItem(String key) : super(key: key);

  /// {@macro act_local_storage_manager.AbsStorageItem.load}
  @override
  Future<T?> load() async => PropertiesSingleton.instance.load<T>(key: key);

  /// {@macro act_local_storage_manager.AbsStorageItem.storeImpl}
  @override
  Future<bool> storeImpl(T value) async =>
      PropertiesSingleton.instance.store<T>(key: key, value: value);

  /// {@macro act_local_storage_manager.AbsStorageItem.deleteImpl}
  @override
  Future<void> deleteImpl() async => PropertiesSingleton.instance.delete(key: key);
}
