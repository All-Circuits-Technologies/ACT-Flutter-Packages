// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecretsSingleton extends AbsWithLifeCycle {
  static SecretsSingleton? _instance;

  static SecretsSingleton get instance => _instance!;

  static SecretsSingleton createInstance(FlutterSecureStorage secureStorage) {
    _instance ??= SecretsSingleton._(secureStorage: secureStorage);
    return _instance!;
  }

  /// This is the secure storage instance to use for the items
  final FlutterSecureStorage secureStorage;

  SecretsSingleton._({
    required this.secureStorage,
  });
}
