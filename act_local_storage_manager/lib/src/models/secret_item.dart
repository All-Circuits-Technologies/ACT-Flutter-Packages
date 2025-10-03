// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/src/models/abs_storage_item.dart';
import 'package:act_local_storage_manager/src/services/secrets_singleton.dart';

/// [SecretItem] wraps a single secret of type T, providing strongly-typed read
/// and write helpers.
///
/// If you don't want to keep those data secret, please consider to use `SharedPreferencesItem`.
///
/// {@macro act_local_storage_manager.MixinStringStorageSingleton.supportedTypes}
///
/// If you want to support another type, please use `SecretItemWithParser` object.
class SecretItem<T> extends AbsStorageItem<T> {
  /// Can this secret be migrated to a new device.
  ///
  /// This setting only applies for iOS devices.
  final bool doNotMigrate;

  /// Create a FlutterSecureStorage wrapper for key [key] of type T.
  const SecretItem(
    String key, {
    this.doNotMigrate = false,
  }) : super(
          key: key,
        );

  /// {@macro act_local_storage_manager.AbsStorageItem.load}
  @override
  Future<T?> load() async => SecretsSingleton.instance.load<T>(key: key);

  /// {@macro act_local_storage_manager.AbsStorageItem.store}
  @override
  Future<bool> store(T? value) async =>
      SecretsSingleton.instance.store(key: key, value: value, doNotMigrate: doNotMigrate);

  /// Delete a value stored in secure storage.
  ///
  /// {@macro act_local_storage_manager.SecretsSingleton.exceptions}
  @override
  Future<void> delete() async => SecretsSingleton.instance.delete(key: key);

  /// Class properties
  @override
  List<Object?> get props => [...super.props, doNotMigrate];
}
