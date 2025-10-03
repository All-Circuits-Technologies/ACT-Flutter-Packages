// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_web_local_storage_manager/src/services/cookie_session_singleton.dart';

/// This is the mixin on the [AbstractPropertiesManager] to use session cookies
mixin MixinSessionProperties on AbstractPropertiesManager {
  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    CookieSessionSingleton.createInstance();
  }

  /// {@macro act_local_storage_manager.AbstractPropertiesManager.deleteAll}
  @override
  Future<void> deleteAll() async {
    await CookieSessionSingleton.instance.deleteAll();
    return super.deleteAll();
  }
}
