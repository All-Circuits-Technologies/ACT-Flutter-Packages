// SPDX-FileCopyrightText: 2025 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/src/mixins/mixin_storage_singleton.dart';
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
///
/// {@macro act_local_storage_manager.SecretsSingleton.exceptions}
class SecretItem<T> extends AbsStorageItem<T> {
  /// Can this secret be migrated to a new device.
  ///
  /// This setting only applies for iOS devices.
  final bool doNotMigrate;

  /// {@macro act_local_storage_manager.AbsStorageItem.storage}
  @override
  MixinStorageSingleton get storage => SecretsSingleton.instance;

  /// {@macro act_local_storage_manager.AbsStorageItem.storageExtra}
  ///
  /// It is [doNotMigrate], which the secrets storage writes the secret with.
  @override
  Object? get storageExtra => doNotMigrate;

  /// Create a FlutterSecureStorage wrapper for key [key] of type T.
  const SecretItem(String key, {this.doNotMigrate = false}) : super(key: key);

  /// Class properties
  @override
  List<Object?> get props => [...super.props, doNotMigrate];
}
