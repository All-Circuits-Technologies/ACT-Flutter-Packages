// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_local_storage_manager/src/services/properties_singleton.dart';

/// [SharedPreferencesItem] wraps a single property of type T,
/// providing strongly-typed load and store helpers.
///
/// Such data is stored in plain text, hence should not be secret.
/// For secrets, please see `SecretItem`.
class SharedPreferencesItem<T> {
  /// The key used to access wrapped data inside SharedPreferences.
  final String key;

  final StreamController<T> _updateStreamController;

  /// With this stream you can subscribe to data update
  Stream get updateStream => _updateStreamController.stream;

  /// Create a SharedPreferences wrapper for key [key] of type T.
  ///
  /// Only [AbstractPropertiesManager] creates instances of this helper class.
  /// Other actors uses them.
  SharedPreferencesItem(this.key) : _updateStreamController = StreamController.broadcast();

  /// Load value from storage.
  ///
  /// Returns null if preference item is not found (if it has never been stored
  /// or if it has been deleted meanwhile).
  ///
  /// Null is also returned in the very unlikely case of type mismatch.
  /// This unlikely since we save the value ourselves in same T type.
  Future<T?> load() async {
    switch (T) {
      case const (bool):
      case const (int):
      case const (double):
      case const (String):
        return _getElement<T, T>(key: key);

      case const (DateTime):
        return _getElement<DateTime, int>(
            key: key,
            castMethod: (value) => DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)) as T;

      default:
        // An unsupported T item was added to PropertiesManager.
        // Dear developer, please add the support for your specific T.
        appLogger().e("Unsupported type $T for key $key");
        return Future.error("Unsupported type $T for key $key");
    }
  }

  /// Useful method to get an element from memory
  ///
  /// If the [castMethod] param is set, this allows to cast a value from the one retrieved from
  /// memory to the expected type
  static Future<ResultType?> _getElement<ResultType, RetrievedFromPrefsType>({
    required String key,
    ResultType Function(RetrievedFromPrefsType)? castMethod,
  }) async {
    final prefs = PropertiesSingleton.instance.prefs;

    final dynamic value = prefs.get(key);

    // We need to test if value is equals to null, because the test:
    // value is T, isn't right when the value is equal to null
    if (value == null) {
      return null;
    }

    if (castMethod == null) {
      if (value is! ResultType) {
        appLogger().e("Key $key loaded as $value instead of type $ResultType");
        return Future.error("Key $key loaded as $value instead of type $ResultType");
      }

      return value;
    }

    if (value is! RetrievedFromPrefsType) {
      appLogger().e("Key $key loaded as $value instead of type $RetrievedFromPrefsType");
      return Future.error("Key $key loaded as $value instead of type $RetrievedFromPrefsType");
    }

    return castMethod(value);
  }

  /// Store value to underlying storage.
  Future<bool> store(T value) async {
    final prefs = PropertiesSingleton.instance.prefs;
    var success = false;

    switch (T) {
      case const (bool):
        success = await prefs.setBool(key, value as bool);
        break;
      case const (int):
        success = await prefs.setInt(key, value as int);
        break;
      case const (double):
        success = await prefs.setDouble(key, value as double);
        break;
      case const (String):
        success = await prefs.setString(key, value as String);
        break;
      case const (DateTime):
        success = await prefs.setInt(key, (value as DateTime).millisecondsSinceEpoch);
        break;
      default:
        // An unsupported T item was added to PropertiesManager.
        // Dear developer, please add the support for your specific T.
        appLogger().e("Unsupported type $T");
        return Future.error("Unsupported type $T");
    }

    if (!success) {
      return false;
    }

    if (!_updateStreamController.isClosed) {
      _updateStreamController.add(value);
    }

    return true;
  }

  /// Remove value from storage.
  ///
  /// This is actually equivalent to storing a null value.
  Future<void> delete() async => PropertiesSingleton.instance.prefs.remove(key);
}
