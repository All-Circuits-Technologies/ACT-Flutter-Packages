// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_local_storage_manager/src/mixins/mixin_storage_singleton.dart';
import 'package:act_local_storage_manager/src/mixins/mixin_string_storage_singleton.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// This is the singleton used to (only) access the secrets storage.
///
/// This singleton has to only be used for internal purpose of the library.
///
/// We use singleton instead of managers because the secrets manager is an abstract class and
/// it will be complicated for the secret item to access the manager with `getIt` not knowing the
/// final type.
///
/// {@template act_local_storage_manager.SecretsSingleton.exceptions}
/// iOS: Those secrets are not accessible after a restart of the device,
/// until device is unlocked once. A `PlatformException` will be thrown
/// if an access is attempted in this case.
/// {@endtemplate}
///
/// {@macro act_local_storage_manager.MixinStringStorageSingleton.supportedTypes}
class SecretsSingleton extends AbsWithLifeCycle
    with MixinStorageSingleton, MixinStringStorageSingleton {
  /// This is the singleton instance
  static SecretsSingleton? _instance;

  /// This is the instance getter
  ///
  /// If the singleton doesn't exist, this throws an exception
  static SecretsSingleton get instance {
    if (_instance == null) {
      throw ActSingletonNotCreatedError<SecretsSingleton>();
    }

    return _instance!;
  }

  /// Create the [SecretsSingleton] singleton.
  static SecretsSingleton createInstance() {
    _instance ??= SecretsSingleton._(
        secureStorage: const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    ));
    return _instance!;
  }

  /// This is the secure storage instance to use for the items
  final FlutterSecureStorage _secureStorage;

  /// Private constructor
  SecretsSingleton._({
    required FlutterSecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  /// {@macro act_local_storage_manager.MixinStorageSingleton.store}
  @override
  Future<bool> store<T>({
    required String key,
    required T? value,
    bool doNotMigrate = false,
    Object? extra,
  }) async =>
      super.store(key: key, value: value, extra: doNotMigrate);

  /// {@macro act_local_storage_manager.MixinStorageSingleton.delete}
  @override
  Future<void> delete({required String key, Object? extra}) async =>
      _secureStorage.delete(key: key);

  /// {@macro act_local_storage_manager.MixinStorageSingleton.deleteAll}
  @override
  Future<void> deleteAll({Object? extra}) async => _secureStorage.deleteAll();

  /// {@macro act_local_storage_manager.MixinStringStorageSingleton.readValueFromExternalService}
  @override
  Future<String?> readValueFromExternalService({required String key, Object? extra}) async =>
      _secureStorage.read(key: key);

  /// {@macro act_local_storage_manager.MixinStringStorageSingleton.writeValueToExternalService}
  ///
  /// Because we override [store] and set the doNotMigrate value in extra, we know that we get
  /// a not null and boolean extra value
  @override
  Future<bool> writeValueToExternalService({
    required String key,
    required String value,
    Object? extra,
  }) async {
    await _secureStorage.write(
        key: key,
        value: value,
        iOptions: IOSOptions(
            accessibility: (extra! as bool)
                ? KeychainAccessibility.first_unlock_this_device
                : KeychainAccessibility.first_unlock));
    return true;
  }
}
