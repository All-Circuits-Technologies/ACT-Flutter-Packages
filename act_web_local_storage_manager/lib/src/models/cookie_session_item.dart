// SPDX-FileCopyrightText: 2025 - 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_web_local_storage_manager/src/services/cookie_session_singleton.dart';

/// This is the cookie session item
///
/// Use this class to store data in session cookies
///
/// {@macro act_local_storage_manager.MixinStringStorageSingleton.supportedTypes}
///
/// If you want to support another type, please use `CookieSessionItemWithParser` object.
class CookieSessionItem<T> extends AbsStorageItem<T> {
  /// {@macro act_local_storage_manager.AbsStorageItem.storage}
  @override
  MixinStorageSingleton get storage => CookieSessionSingleton.instance;

  /// Class constructor
  const CookieSessionItem(String key) : super(key: key);
}
