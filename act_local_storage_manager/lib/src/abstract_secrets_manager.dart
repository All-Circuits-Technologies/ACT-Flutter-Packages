// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Builder for creating the SecretsManager
abstract class AbstractSecretsBuilder<
    P extends AbstractPropertiesManager,
    E extends MixinStoresConf,
    T extends AbstractSecretsManager<P, E>> extends AbsManagerBuilder<T> {
  /// A factory to create a manager instance
  AbstractSecretsBuilder(super.factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager, P, E];
}

/// [SecretsManager] handles confidential data storage.
///
/// (for non-secret data, please see [PropertiesManager])
///
/// Each supported secret is accessible through a public member,
/// which provides a getter and a setter to read from secure storage and
/// save to secure storage respectively.
///
/// Data is not always accessible
/// -----------------------------
///
/// iOS: Those secrets are not accessible after a restart of the device,
/// until device is unlocked once. A [PlatformException] will be thrown
/// if an access is attempted in this case.
abstract class AbstractSecretsManager<P extends AbstractPropertiesManager,
    E extends MixinStoresConf> extends AbsWithLifeCycle {
  /// This is the secure storage instance to use for the items
  late final FlutterSecureStorage _secureStorage;

  /// Builds an instance of [SecretsManager].
  ///
  /// You may want to use created instance as a singleton
  /// in order to save memory.
  AbstractSecretsManager() : super();

  /// Delete all stored secrets.
  ///
  /// Can throw a [PlatformException].
  Future<void> deleteAll() async => _secureStorage.deleteAll();

  /// Init the manager
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );

    final isFirstStart = globalGetIt().get<P>().isFirstStart;

    final isNeededToDeleteAll = globalGetIt().get<E>().cleanSecretStorageWhenReinstall.load();

    // Check if app has already been run
    if (isFirstStart && isNeededToDeleteAll) {
      // Delete all keys associated with app,
      // this is required because of iOS keychain behaviour
      await deleteAll();
    }
  }
}

/// [SecretItem] wraps a single secret of type T, providing strongly-typed read
/// and write helpers.
///
/// Underlying secret storage only support strings, hence all other types are
/// converted to and from strings.
class SecretItem<T, S extends AbstractSecretsManager> {
  /// The key used to access wrapped data inside SharedPreferences.
  final String key;

  /// Can this secret be migrated to a new device.
  ///
  /// This setting only applies for iOS devices.
  final bool doNotMigrate;

  /// The common secure storage shared for all the secret items linked to the SecretsManager
  FlutterSecureStorage? _commonSecureStorage;

  /// This getter allows to get the secure storage shared with all the other items
  FlutterSecureStorage get secureStorage {
    _commonSecureStorage ??= globalGetIt().get<S>()._secureStorage;

    return _commonSecureStorage!;
  }

  /// Create a FlutterSecureStorage wrapper for key [key] of type T.
  ///
  /// Only [PropertiesManager] creates instances of this helper class.
  /// Other actors uses them.
  SecretItem(
    this.key, {
    this.doNotMigrate = false,
  }) : _commonSecureStorage = null;

  /// Load value from secure storage.
  ///
  /// Never returns null (thanks to the async keyword),
  /// but returns Future<T>(null) if value is not found or fails to be parsed.
  ///
  /// Can (unlikely) return a Future.error.
  /// Can throw a [PlatformException] (see [SecretsManager] iOS note).
  Future<T?> load() async {
    final value = await secureStorage.read(key: key);

    return StringUtility.parseStrValue(value);
  }

  /// Store value to secure storage.
  ///
  /// Can throw a [PlatformException] (see [SecretsManager] iOS note).
  Future<void> store(T value) async {
    if (value == null) {
      // Underlying storage can not store null values, no need to ge further.
      // Deleting the key appears to be the closest supported action,
      // and loading it back will result in a null value as expected.
      return delete();
    }

    String valueStr;

    switch (T) {
      case const (bool):
        valueStr = (value as bool).toString();
        break;
      case const (int):
        valueStr = (value as int).toString();
        break;
      case const (double):
        valueStr = (value as double).toString();
        break;
      case const (String):
        valueStr = value as String;
        break;
      default:
        // A _SecretItem<unsupported T> member was added to SecretsManager.
        // Dear developer, please add the support for your specific T.
        appLogger().e('Unsupported type $T');
        return Future.error('Unsupported type $T');
    }

    return secureStorage.write(
        key: key,
        value: valueStr,
        iOptions: IOSOptions(
            accessibility: doNotMigrate
                ? KeychainAccessibility.first_unlock_this_device
                : KeychainAccessibility.first_unlock));
  }

  /// Delete a value stored in secure storage.
  ///
  /// Can throw a [PlatformException] (see [SecretsManager] iOS note).
  Future<void> delete() async => secureStorage.delete(key: key);
}
