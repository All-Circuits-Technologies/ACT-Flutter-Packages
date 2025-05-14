// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
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
class SecretsSingleton extends AbsWithLifeCycle {
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

  /// Create the [SecretsSingleton] singleton from the given [secureStorage].
  static SecretsSingleton createInstance(FlutterSecureStorage secureStorage) {
    _instance ??= SecretsSingleton._(secureStorage: secureStorage);
    return _instance!;
  }

  /// This is the secure storage instance to use for the items
  final FlutterSecureStorage secureStorage;

  /// Private constructor
  SecretsSingleton._({
    required this.secureStorage,
  });
}
