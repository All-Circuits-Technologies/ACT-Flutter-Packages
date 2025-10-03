// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_local_storage_manager/src/errors/act_type_not_matching_target_error.dart';
import 'package:act_local_storage_manager/src/mixins/mixin_storage_singleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// This is the singleton used to (only) access the local storage.
///
/// This singleton has to only be used for internal purpose of the library.
///
/// We use singleton instead of managers because the properties manager is an abstract class and
/// it will be complicated for the property item to access the manager with `getIt` not knowing the
/// final type.
///
/// {@template act_local_storage_manager.PropertiesSingleton.details}
/// Not suitable for secrets
/// ------------------------
///
/// This class uses SharedPreferences storage backend, which uses a clear-text
/// XML file within application private storage. This storage is normally  not
/// accessible to other apps, but can be read back by advanced users or by any
/// app on a rooted device.
///
/// For secret data, please see `SecretsManager`.
///
/// Can be removed by user
/// ----------------------
///
/// Backend storage is removed when user uninstalls the application.
/// It is also removed when user clears application data.
///
/// In those two case, all defined properties are lost.
/// {@endtemplate}
///
/// {@template act_local_storage_manager.PropertiesSingleton.supportedTypes}
/// The cast and types supported by this singleton are:
///
/// - bool
/// - int
/// - double
/// - String
/// - List\<String\>
/// {@endtemplate}
class PropertiesSingleton extends AbsWithLifeCycle with MixinStorageSingleton {
  /// This is the singleton instance
  static PropertiesSingleton? _instance;

  /// This is the instance getter
  ///
  /// If the singleton doesn't exist, this throws an exception
  static PropertiesSingleton get instance {
    if (_instance == null) {
      throw ActSingletonNotCreatedError<PropertiesSingleton>();
    }

    return _instance!;
  }

  /// Create the [PropertiesSingleton] singleton.
  static PropertiesSingleton createInstance() {
    _instance ??= PropertiesSingleton._(prefs: SharedPreferencesAsync());
    return _instance!;
  }

  /// This is the properties storage instance to use for the items
  final SharedPreferencesAsync _prefs;

  /// Private constructor
  PropertiesSingleton._({
    required SharedPreferencesAsync prefs,
  }) : _prefs = prefs;

  /// {@macro act_local_storage_manager.MixinStorageSingleton.load}
  @override
  Future<T?> load<T>({required String key, Object? extra}) async {
    switch (T) {
      case const (bool):
        return _getElement<bool, bool>(key: key, prefsGetter: _prefs.getBool) as T?;
      case const (int):
        return _getElement<int, int>(key: key, prefsGetter: _prefs.getInt) as T?;
      case const (double):
        return _getElement<double, double>(key: key, prefsGetter: _prefs.getDouble) as T?;
      case const (String):
        return _getElement<String, String>(key: key, prefsGetter: _prefs.getString) as T?;
      case const (List<String>):
        return _getElement<List<String>, List<String>>(key: key, prefsGetter: _prefs.getStringList)
            as T?;

      default:
        // An unsupported T item was added to PropertiesManager.
        // Dear developer, please add the support for your specific T.
        appLogger().e("Unsupported type $T for key $key");
        throw ActUnsupportedTypeError<T>(
          context: "key: $key",
        );
    }
  }

  /// {@macro act_local_storage_manager.MixinStorageSingleton.store}
  @override
  Future<bool> store<T>({required String key, required T? value, Object? extra}) async {
    if (value == null) {
      await delete(key: key);
      return true;
    }

    var success = false;

    switch (T) {
      case const (bool):
        success = await _setElement(
          key: key,
          prefsSetter: _prefs.setBool,
          value: value as bool,
        );
        break;
      case const (int):
        success = await _setElement(
          key: key,
          prefsSetter: _prefs.setInt,
          value: value as int,
        );
        break;
      case const (double):
        success = await _setElement(
          key: key,
          prefsSetter: _prefs.setDouble,
          value: value as double,
        );
        break;
      case const (String):
        success = await _setElement(
          key: key,
          prefsSetter: _prefs.setString,
          value: value as String,
        );
        break;
      case const (List<String>):
        success = await _setElement(
          key: key,
          prefsSetter: _prefs.setStringList,
          value: value as List<String>,
        );
        break;
      default:
        // An unsupported T item was added to PropertiesManager.
        // Dear developer, please add the support for your specific T.
        appLogger().e("Unsupported type $T");
        throw ActUnsupportedTypeError<T>(
          context: "key: $key",
        );
    }

    return success;
  }

  /// {@macro act_local_storage_manager.MixinStorageSingleton.delete}
  @override
  Future<void> delete({required String key, Object? extra}) async => _prefs.remove(key);

  /// {@macro act_local_storage_manager.MixinStorageSingleton.deleteAll}
  @override
  Future<void> deleteAll({Object? extra}) async => _prefs.clear();

  /// Useful method to get an element from memory
  ///
  /// If the [castMethod] param is set, this allows to cast a value from the one retrieved from
  /// memory to the expected type
  static Future<ResultType?> _getElement<ResultType, RetrievedFromPrefsType>({
    required String key,
    required Future<RetrievedFromPrefsType?> Function(String key) prefsGetter,
    ResultType Function(RetrievedFromPrefsType)? castMethod,
  }) async {
    RetrievedFromPrefsType? result;
    try {
      result = await prefsGetter(key);
    } catch (error) {
      appLogger().e("An error occurred when tried to get the shared preferences from key: $key"
          "the error: $error");
    }

    // We need to test if value is equals to null, because the test:
    // value is T, isn't right when the value is equal to null
    if (result == null) {
      return null;
    }

    if (castMethod == null) {
      if (result is! ResultType) {
        appLogger().e("Key $key loaded as $result instead of type $ResultType");
        throw ActTypeNotMatchingTargetError<ResultType>(key: key, value: result);
      }

      return result as ResultType;
    }

    return castMethod(result);
  }

  /// Useful method to set an element to memory
  static Future<bool> _setElement<StoredType>({
    required String key,
    required Future<void> Function(String key, StoredType value) prefsSetter,
    required StoredType value,
  }) async {
    var result = false;
    try {
      await prefsSetter(key, value);
      result = true;
    } catch (error) {
      appLogger().e("An error occurred when tried to store the value: $value, of key: $key, into "
          "the properties");
    }
    return result;
  }
}
