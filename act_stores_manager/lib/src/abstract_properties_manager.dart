// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builder for creating the PropertiesManager
abstract class AbstractPropertiesBuilder<T extends AbstractPropertiesManager>
    extends ManagerBuilder<T> {
  /// A factory to create a manager instance
  AbstractPropertiesBuilder(ClassFactory<T> factory) : super(factory);

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// [PropertiesManager] handles non-secret settings and preferences storage.
///
/// Each supported property is accessible through a public member,
/// which provides a getter and a setter to read from settings and
/// save to settings respectively.
///
/// Not suitable for secrets
/// ------------------------
///
/// This class uses SharedPreferences storage backend, which uses a clear-text
/// XML file within application private storage. This storage is normally  not
/// accessible to other apps, but can be read back by advanced users or by any
/// app on a rooted device.
///
/// For secret data, please see [SecretsManager].
///
/// Can be removed by user
/// ----------------------
///
/// Backend storage is removed when user uninstalls the application.
/// It is also removed when user clears application data.
///
/// In those two case, all defined properties are lost.
abstract class AbstractPropertiesManager extends AbstractManager {
  /// Tell if it's the first start of the app after install
  final SharedPreferencesItem<bool> _isFirstStart = SharedPreferencesItem<bool>("isFirstStart");

  /// True if it's the first start of the application
  bool isFirstStart;

  /// Builds an instance of [PropertiesManager].
  ///
  /// You may want to use created instance as a singleton
  /// in order to save memory.
  AbstractPropertiesManager()
      : isFirstStart = true,
        super();

  /// Init the manager
  @override
  Future<void> initManager() async {
    try {
      isFirstStart = await _isFirstStart.load() ?? isFirstStart;
    } catch (error) {
      appLogger().e("An error occurred when trying to get isFirstStart properties : $error");
    }

    // Check if app has already been run
    if (isFirstStart) {
      // Next app start will no more be first one.
      // We keep isFirstStart true so app can say we are currently in the first start
      await _isFirstStart.store(false);
    }
  }

  /// Delete all stored properties.
  Future<void> deleteAll() async => SharedPreferences.getInstance().then((prefs) => prefs.clear());
}

/// [SharedPreferencesItem] wraps a single property of type T,
/// providing strongly-typed load and store helpers.
///
/// Such data is stored in plain text, hence should not be secret.
/// For secrets, please see [SecretItem].
class SharedPreferencesItem<T> {
  /// The key used to access wrapped data inside SharedPreferences.
  final String key;

  final StreamController<T> _updateStreamController;

  /// With this stream you can subscribe to data update
  Stream get updateStream => _updateStreamController.stream;

  /// Create a SharedPreferences wrapper for key [key] of type T.
  ///
  /// Only [PropertiesManager] creates instances of this helper class.
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
      case bool:
      case int:
      case double:
      case String:
        return _getElement<T, T>(key: key);

      case DateTime:
        return _getElement<DateTime, int>(
            key: key,
            castMethod: (value) {
              return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
            }) as T;

      default:
        // An unsupported T item was added to PropertiesManager.
        // Dear developer, please add the support for your specific T.
        appLogger().e("Unsupported type $T for key $key");
        return Future.error("Unsupported type $T for key $key");
    }
  }

  /// Useful method to get an element from memory
  ///
  /// If the [castMethod] param is set, this allows to cast a value from the one got from memory to
  /// the expected type
  static Future<ResultType?> _getElement<ResultType, GotFromPrefsType>({
    required String key,
    ResultType Function(GotFromPrefsType)? castMethod,
  }) async {
    final prefs = await SharedPreferences.getInstance();

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

    if (value is! GotFromPrefsType) {
      appLogger().e("Key $key loaded as $value instead of type $GotFromPrefsType");
      return Future.error("Key $key loaded as $value instead of type $GotFromPrefsType");
    }

    return castMethod(value);
  }

  /// Store value to underlying storage.
  Future<bool> store(T value) async {
    final prefs = await SharedPreferences.getInstance();
    var success = false;

    switch (T) {
      case bool:
        success = await prefs.setBool(key, value as bool);
        break;
      case int:
        success = await prefs.setInt(key, value as int);
        break;
      case double:
        success = await prefs.setDouble(key, value as double);
        break;
      case String:
        success = await prefs.setString(key, value as String);
        break;
      case DateTime:
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
  Future<void> delete() async => SharedPreferences.getInstance().then((prefs) => prefs.remove(key));
}
