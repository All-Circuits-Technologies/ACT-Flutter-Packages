// Copyright (c) 2020. BMS Circuits

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
  /// Builds an instance of [PropertiesManager].
  ///
  /// You may want to use created instance as a singleton
  /// in order to save memory.
  AbstractPropertiesManager() : super();

  /// Init the manager
  @override
  Future<void> initManager() async => null;

  /// Delete all stored properties.
  Future<void> deleteAll() async =>
      SharedPreferences.getInstance().then((prefs) => prefs.clear());
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

  /// Create a SharedPrefrences wrapper for key [key] of type T.
  ///
  /// Only [PropertiesManager] creates instances of this helper class.
  /// Other actors uses them.
  SharedPreferencesItem(this.key)
      : _updateStreamController = StreamController.broadcast();

  /// Load value from storage.
  ///
  /// Returns null if preference item is not found (if it has never been stored
  /// or if it has been deleted meanwhile).
  ///
  /// Null is also returned in the very unlikely case of type mismatch.
  /// This unlikely since we save the value ourselves in same T type.
  Future<T> load() async {
    final prefs = await SharedPreferences.getInstance();

    switch (T) {
      case bool:
      case int:
      case double:
      case String:
        final dynamic value = prefs.get(key);

        // We need to test if value is equals to null, because the test:
        // value is T, isn't right when the value is equal to null
        if (value == null) {
          return null;
        }

        // The expected case (should always be true).
        if (value is T) {
          return value;
        }

        // The bad case.
        // Developer is likely re-using an old key with a new T (not advised),
        // or uses same key for several items (absolutely wrong and severe).
        // Returning a Future.error for this time.
        // If we are facing the first case, then next store call will fix it.
        AppLogger().e("Key $key loaded as $value instead of type $T");
        return Future.error("Key $key loaded as $value instead of type $T");

      default:
        // An unsupported T item was added to PropertiesManager.
        // Dear developer, please add the support for your specific T.
        AppLogger().e("Unsupported type $T");
        return Future.error("Unsupported type $T");
    }
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
      /*case List<String>: return prefs.setStringList(key, value);*/
      default:
        // An unsupported T item was added to PropertiesManager.
        // Dear developer, please add the support for your specific T.
        AppLogger().e("Unsupported type $T");
        return Future.error("Unsupported type $T");
    }

    if (!success) {
      return false;
    }

    _updateStreamController.add(value);
    return true;
  }

  /// Remove value from storage.
  ///
  /// This is actually equivalent to storing a null value.
  Future<void> delete() async =>
      SharedPreferences.getInstance().then((prefs) => prefs.remove(key));
}
