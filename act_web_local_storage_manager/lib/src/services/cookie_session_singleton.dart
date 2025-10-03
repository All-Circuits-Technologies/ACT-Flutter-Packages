// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:web/web.dart';

/// Allows to store and load session cookies.
///
/// The only way to remove a cookie is to set its expiration date to a non valid date. And so the
/// cookie is removed when the browser when we reopen it. But this is what we already does because
/// we explicitly want session cookie.
///
/// Therefore, we consider that an empty value it's like we want the element to be removed.
///
/// Because, we aren't the only ones which manage the cookies list, we don't want to delete all.
/// Therefore, the method does nothing.
class CookieSessionSingleton extends AbsWithLifeCycle
    with MixinStorageSingleton, MixinStringStorageSingleton {
  /// This is the separator between cookie elements
  static const _cookieElementSeparator = ";";

  /// This is the separator between cookie key and value
  static const _cookieValueSeparator = "=";

  /// This is the singleton instance
  static CookieSessionSingleton? _instance;

  /// This is the instance getter
  ///
  /// If the singleton doesn't exist, this throws an exception
  static CookieSessionSingleton get instance {
    if (_instance == null) {
      throw ActSingletonNotCreatedError<CookieSessionSingleton>();
    }

    return _instance!;
  }

  /// Create the [CookieSessionSingleton] singleton.
  static CookieSessionSingleton createInstance() {
    _instance ??= CookieSessionSingleton._();
    return _instance!;
  }

  /// Class constructor
  CookieSessionSingleton._();

  /// {@macro act_local_storage_manager.MixinStringStorageSingleton.isReadValueValid}
  @override
  bool isReadValueValid({required String? value}) =>
      // We know that the super isReadValue tests for nullity
      super.isReadValueValid(value: value) && value!.isEmpty;

  /// {@macro act_local_storage_manager.MixinStorageSingleton.delete}
  @override
  Future<void> delete({required String key, Object? extra}) async {
    // We set an empty value
    _setCookieValue(name: key, value: "");
  }

  /// {@macro act_local_storage_manager.MixinStorageSingleton.deleteAll}
  @override
  Future<void> deleteAll({Object? extra}) async {
    // We don't know to update cookies we don't manage; therefore, we don't do anything in this
    // method
    appLogger().w("The delete all for cookie session doesn't work, don't use it");
  }

  /// {@macro act_local_storage_manager.MixinStringStorageSingleton.readValueFromExternalService}
  @override
  Future<String?> readValueFromExternalService({required String key, Object? extra}) async =>
      _getCookieValue(name: key);

  /// {@macro act_local_storage_manager.MixinStringStorageSingleton.writeValueToExternalService}
  @override
  Future<bool> writeValueToExternalService({
    required String key,
    required String value,
    Object? extra,
  }) async {
    _setCookieValue(name: key, value: value);
    return true;
  }

  /// Get the value of the cookie named: [name]
  String? _getCookieValue({required String name}) {
    final cookie = document.cookie;
    final cookiesElements = cookie.split(_cookieElementSeparator);

    String? cookieValue;
    for (final cookie in cookiesElements) {
      if (!cookie.startsWith("$name$_cookieValueSeparator")) {
        // We haven't found it
        continue;
      }

      final cookieValueParts = cookie.split(_cookieValueSeparator);
      cookieValue = cookieValueParts[1];
    }

    return cookieValue;
  }

  /// Set the value of the cookie.
  ///
  /// If we set an empty value, it means that the cookie doesn't exist.
  void _setCookieValue({required String name, required String value}) {
    document.cookie = "$name$_cookieValueSeparator$value";
  }
}
