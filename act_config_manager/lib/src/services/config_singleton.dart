// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_config_manager/src/data/config_constants.dart' as config_constants;

/// This singleton is used to load and get the config variables.
///
/// We prefer to use a singleton here instead of using the [AbstractConfigManager], because the
/// [AbstractConfigManager] has to be gotten through the GlobalManager and we don't know its derived
/// type.
///
/// Therefore, it won't be easy to get this instance in all the [AbsConfigVar] derived classes.
///
/// To use a singleton here simplifies all the process even if it doesn't match the manager design
/// pattern.
class ConfigSingleton extends AbstractService {
  /// The final config values
  final Map<String, dynamic> _configs;

  /// The instance of this singleton
  static ConfigSingleton? _instance;

  /// Getter to this instance
  ///
  /// This class has to be created by calling [createInstance] before calling this getter
  static ConfigSingleton get instance => _instance!;

  /// Create the singleton instance.
  ///
  /// This method has to be called only once or an exception will be raised.
  static ConfigSingleton createInstance(Map<String, dynamic> configs) {
    if (_instance != null) {
      throw Exception("Configs service has already been created, don't do it again");
    }

    _instance = ConfigSingleton._(configs);
    return _instance!;
  }

  /// Private class constructor
  ConfigSingleton._(this._configs);

  /// Init service
  @override
  Future<void> initService() async {}

  /// Load value from config variable.
  ///
  /// If the variable doesn't exist, it will return null.
  T? tryToGet<T>(String key) {
    final value = _getMapValue(key);

    if (value == null || value is! T) {
      return null;
    }

    return value;
  }

  /// Load a list of values from config variable.
  ///
  /// If the variable doesn't exist, it will return null.
  List<T>? tryToGetList<T>(String key) {
    final tmpList = tryToGet<List<dynamic>>(key);

    if (tmpList == null) {
      return null;
    }

    try {
      return List<T>.from(tmpList, growable: false);
    } catch (_) {
      return null;
    }
  }

  /// Find, thanks to the given key, the expected object
  ///
  /// If the object isn't found or if a problem occurred, the method returns null.
  dynamic _getMapValue(String key) {
    final keyPaths = key.split(config_constants.keyPathsSeparator);

    if (keyPaths.isEmpty) {
      // Nothing found
      return null;
    }

    // We remove empty path
    keyPaths.removeWhere((element) => element.isEmpty);

    final lastIdx = keyPaths.length - 1;
    var currentMap = _configs;
    for (var idx = 0; idx <= lastIdx; ++idx) {
      final path = keyPaths[idx];
      final tmpValue = currentMap[path];
      if (idx == lastIdx) {
        return tmpValue;
      }

      if (tmpValue is! Map<String, dynamic>) {
        // We want to continue the progression in the map but the value is not map; therefore,
        // nothing can be found
        return null;
      }

      currentMap = tmpValue;
    }

    // Nothing has been found
    return null;
  }
}
