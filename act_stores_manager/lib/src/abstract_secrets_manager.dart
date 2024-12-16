// Copyright (c) 2020. BMS Circuits

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Builder for creating the SecretsManager
abstract class AbstractSecretsBuilder<T extends AbstractSecretsManager>
    extends ManagerBuilder<T> {
  /// A factory to create a manager instance
  AbstractSecretsBuilder(ClassFactory<T> factory) : super(factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
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
abstract class AbstractSecretsManager extends AbstractManager {
  /// Builds an instance of [SecretsManager].
  ///
  /// You may want to use created instance as a singleton
  /// in order to save memory.
  AbstractSecretsManager() : super();

  /// Delete all stored secrets.
  ///
  /// Can throw a [PlatformException].
  Future<void> deleteAll() async {
    return FlutterSecureStorage().deleteAll();
  }

  /// Init the manager
  @override
  Future<void> initManager() async => null;
}

/// [SecretItem] wraps a single secret of type T, providing strongly-typed read
/// and write helpers.
///
/// Underlying secret storage only support strings, hence all other types are
/// converted to and from strings.
class SecretItem<T> {
  /// The key used to access wrapped data inside SharedPreferences.
  final String key;

  /// Can this secret be migrated to a new device.
  ///
  /// This setting only applies for iOS devices.
  final bool doNotMigrate;

  /// Create a FlutterSecureStorage wrapper for key [key] of type T.
  ///
  /// Only [PropertiesManager] creates instances of this helper class.
  /// Other actors uses them.
  SecretItem(this.key, {this.doNotMigrate = false});

  /// Load value from secure storage.
  ///
  /// Never returns null (thanks to the async keyword),
  /// but returns Future<T>(null) if value is not found or fails to be parsed.
  ///
  /// Can (unlikely) return a Future.error.
  /// Can throw a [PlatformException] (see [SecretsManager] iOS note).
  Future<T> load() async {
    final String value = await FlutterSecureStorage().read(key: key);

    if (value == null) {
      // No need to attempt a conversion to T,
      // which may even crash in some cases.
      return null;
    }

    switch (T) {
      case bool:
        return BoolHelper.tryParse(value) as T;
      case int:
        return int.tryParse(value) as T;
      case double:
        return double.tryParse(value) as T;
      case String:
        return value as T;
      /*case List<String>: return prefs.setStringList(key, value);*/
      default:
        // A _SecretItem<unsupported T> member was added to SecretsManager
        // Dear developer, please add the support for your specific T.
        AppLogger().e("Unsupported type ${T}");
        return Future.error("Unsupported type ${T}");
    }
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
      case bool:
        valueStr = (value as bool).toString();
        break;
      case int:
        valueStr = (value as int).toString();
        break;
      case double:
        valueStr = (value as double).toString();
        break;
      case String:
        valueStr = value as String;
        break;
      default:
        // A _SecretItem<unsupported T> member was added to SecretsManager.
        // Dear developer, please add the support for your specific T.
        AppLogger().e("Unsupported type ${T}");
        return Future.error("Unsupported type ${T}");
    }

    if (valueStr == null) {
      // Should never occur, but backend storage can not handle this
      // hence it appears wise to catch it and provide a clear action.
      AppLogger().e("Unexpected null stringification");
      return Future.error("Unexpected null stringification");
    }

    return FlutterSecureStorage().write(
        key: key,
        value: valueStr,
        iOptions: IOSOptions(
            accessibility: doNotMigrate == true
                ? IOSAccessibility.first_unlock_this_device
                : IOSAccessibility.first_unlock));
  }

  /// Delete a value stored in secure storage.
  ///
  /// Can throw a [PlatformException] (see [SecretsManager] iOS note).
  Future<void> delete() async {
    return FlutterSecureStorage().delete(key: key);
  }
}
