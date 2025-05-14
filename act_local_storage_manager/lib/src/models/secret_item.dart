// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_local_storage_manager/src/services/secrets_singleton.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  /// This is used to parse the value stored to the wanted type
  ///
  /// Returns null if the `value` given is null or if the parsing has failed
  ///
  /// If [parser] is equal to null, we use [StringUtility.parseStrValue] method to parse the value.
  final T? Function(String? value)? parser;

  /// Cast the `value` given to a string to store in secret storage
  ///
  /// If [castTo] is equals to null, we use the default `toString` method of primitive types. If
  /// the type isn't primitive, an exception may raise.
  final String Function(T value)? castTo;

  /// Create a FlutterSecureStorage wrapper for key [key] of type T.
  const SecretItem(
    this.key, {
    this.doNotMigrate = false,
    this.parser,
    this.castTo,
  });

  /// Load value from secure storage.
  ///
  /// Returns null if value is not found or fails to be parsed.
  ///
  /// If the cast from String to T isn't supported, the method will throw an [UnsupportedError].
  ///
  /// {@macro act_local_storage_manager.SecretsSingleton.exceptions}
  Future<T?> load() async {
    final value = await SecretsSingleton.instance.secureStorage.read(key: key);

    return parser?.call(value) ?? StringUtility.parseStrValue<T>(value);
  }

  /// Store value to secure storage.
  ///
  /// May throw an [UnsupportedError] if T isn't supported.
  ///
  /// {@macro act_local_storage_manager.SecretsSingleton.exceptions}
  Future<void> store(T value) async {
    if (value == null) {
      // Underlying storage can not store null values, no need to ge further.
      // Deleting the key appears to be the closest supported action,
      // and loading it back will result in a null value as expected.
      return delete();
    }

    String valueStr;
    if (castTo != null) {
      valueStr = castTo!.call(value);
    } else {
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
          throw ActUnsupportedTypeError<T>(
            context: "key: $key",
          );
      }
    }

    return SecretsSingleton.instance.secureStorage.write(
        key: key,
        value: valueStr,
        iOptions: IOSOptions(
            accessibility: doNotMigrate
                ? KeychainAccessibility.first_unlock_this_device
                : KeychainAccessibility.first_unlock));
  }

  /// Delete a value stored in secure storage.
  ///
  /// {@macro act_local_storage_manager.SecretsSingleton.exceptions}
  Future<void> delete() async => SecretsSingleton.instance.secureStorage.delete(key: key);
}
