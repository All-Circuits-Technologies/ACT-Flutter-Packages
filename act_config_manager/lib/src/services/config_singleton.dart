// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/src/data/config_constants.dart' as config_constants;
import 'package:act_foundation/act_foundation.dart';
import 'package:act_life_cycle/act_life_cycle.dart';

/// This singleton is used to load and get the config variables.
///
/// We prefer to use a singleton here instead of using the `AbstractConfigManager`, because the
/// `AbstractConfigManager` has to be retrieved through the GlobalManager and we don't know its
/// derived type.
///
/// Therefore, it won't be easy to get this instance in all the `AbsConfigVar` derived classes.
///
/// To use a singleton here simplifies all the process even if it doesn't match the manager design
/// pattern.
class ConfigSingleton extends AbsWithLifeCycle {
  /// The instance of this singleton
  static ConfigSingleton? _instance;

  /// The logger used to log messages in this package.
  final MixinActLogger logger;

  /// The final config values
  final Map<String, dynamic> _configs;

  /// Getter to this instance
  ///
  /// This class has to be created by calling [createInstance] before calling this getter
  static ConfigSingleton get instance {
    if (_instance == null) {
      throw ActSingletonNotCreatedError<ConfigSingleton>();
    }

    return _instance!;
  }

  /// Create the singleton instance.
  ///
  /// This method has to be called only once or an exception will be raised.
  static ConfigSingleton createInstance(
      {required MixinActLogger logger, required Map<String, dynamic> configs}) {
    if (_instance != null) {
      throw ActSingletonAlreadyCreatedError<ConfigSingleton>();
    }

    _instance = ConfigSingleton._(logger: logger, configs: configs);
    return _instance!;
  }

  /// Private class constructor
  ConfigSingleton._({required this.logger, required Map<String, dynamic> configs})
      : _configs = configs;

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
