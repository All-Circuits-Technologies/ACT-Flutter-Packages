// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
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
class PropertiesSingleton extends AbsWithLifeCycle {
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

  /// Create the [PropertiesSingleton] singleton from the given [prefs].
  static PropertiesSingleton createInstance(SharedPreferences prefs) {
    _instance ??= PropertiesSingleton._(prefs: prefs);
    return _instance!;
  }

  /// This is the properties storage instance to use for the items
  final SharedPreferences prefs;

  /// Private constructor
  PropertiesSingleton._({
    required this.prefs,
  });
}
