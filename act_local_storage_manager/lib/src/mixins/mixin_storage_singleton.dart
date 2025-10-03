// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';

/// This is the mixin on the storage singleton
mixin MixinStorageSingleton on AbsWithLifeCycle {
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
  /// Store value to underlying storage.
  ///
  /// If T isn't known, this will raise an [UnsupportedError] error.
  ///
  /// If the value is null, we remove the value from property
  /// {@endtemplate}
  Future<bool> store<T>({required String key, required T? value, Object? extra});

  /// {@template act_local_storage_manager.MixinStorageSingleton.delete}
  /// Remove value from storage.
  ///
  /// This is actually equivalent to storing a null value.
  /// {@endtemplate}
  Future<void> delete({required String key, Object? extra});

  /// {@template act_local_storage_manager.MixinStorageSingleton.deleteAll}
  /// Remove all the value from storage
  /// {@endtemplate}
  Future<void> deleteAll({Object? extra});
}
