// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:flutter/foundation.dart';

/// This is a helpful mixin to define a storage singleton which only store string values
///
/// {@template act_local_storage_manager.MixinStringStorageSingleton.supportedTypes}
/// The cast and types supported by this singleton are:
///
/// - bool
/// - int
/// - double
/// - String
/// {@endtemplate}
mixin MixinStringStorageSingleton on MixinStorageSingleton {
  /// {@macro act_local_storage_manager.MixinStorageSingleton.load}
  @override
  Future<T?> load<T>({required String key, Object? extra}) async {
    final value = await readValueFromExternalService(key: key, extra: extra);
    if (!isReadValueValid(value: value)) {
      return null;
    }

    return StringUtility.parseStrValue<T>(value);
  }

  /// {@macro act_local_storage_manager.MixinStorageSingleton.store}
  @override
  Future<bool> store<T>({required String key, required T? value, Object? extra}) async {
    if (value == null) {
      await delete(key: key);
      return true;
    }

    String? toStoreResult;
    if (value is String) {
      toStoreResult = value;
    } else {
      toStoreResult = _castTo(key, value);
    }

    if (toStoreResult == null) {
      return false;
    }

    return writeValueToExternalService(key: key, value: toStoreResult, extra: extra);
  }

  /// {@template act_local_storage_manager.MixinStringStorageSingleton.readValueFromExternalService}
  /// Read value from external service.
  /// {@endtemplate}
  @protected
  Future<String?> readValueFromExternalService({required String key, Object? extra});

  /// {@template act_local_storage_manager.MixinStringStorageSingleton.isReadValueValid}
  /// Check if the read value is valid.
  /// {@endtemplate}
  @protected
  bool isReadValueValid({required String? value}) => (value != null);

  /// {@template act_local_storage_manager.MixinStringStorageSingleton.writeValueToExternalService}
  /// Write value to external service.
  /// {@endtemplate}
  @protected
  Future<bool> writeValueToExternalService({
    required String key,
    required String value,
    Object? extra,
  });

  /// This is the method used to cast the value to be stored in storage
  static String? _castTo<T>(String key, T value) {
    final valueStrResult = StringUtility.castToString<T>(value);
    if (!valueStrResult.isOk) {
      // A _SecretItem<unsupported T> member was added to SecretsManager.
      // Dear developer, please add the support for your specific T.
      appLogger().e('Unsupported type $T');
      throw ActUnsupportedTypeError<T>(
        context: "key: $key",
      );
    }

    return valueStrResult.value;
  }
}
