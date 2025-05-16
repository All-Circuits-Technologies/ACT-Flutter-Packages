// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/foundation.dart';

/// Builder of the [AbsAuthManager] manager
abstract class AbsAuthBuilder<T extends AbsAuthManager> extends AbsManagerBuilder<T> {
  /// Class constructor
  AbsAuthBuilder(super.factory);

  /// {@macro act_abstract_manager.AbsManagerBuilder.dependsOn}
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// This is the abstract manager for authentication
///
/// This manager is detached of the authentication provider thanks to the [MixinAuthService], which
/// allows to minimize the code refactoring when we want to change the provider.
abstract class AbsAuthManager extends AbsWithLifeCycle {
  /// This is the authentication service to use in the application
  late final MixinAuthService authService;

  /// This is the storage auth service to use in the application in order to store and load from
  /// phone memory the ids and/or tokens
  late final MixinAuthStorageService? storageService;

  /// This is the subscription linked to the auth status stream
  late final StreamSubscription _authStatusSub;

  /// Init the manager
  @override
  @mustCallSuper
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    authService = await getAuthService();
    storageService = await getStorageService();
    if (storageService != null) {
      await authService.setStorageService(storageService);
    }
    _authStatusSub = authService.authStatusStream.listen(onAuthStatusUpdated);
  }

  /// {@template act_shared_auth.AbsAuthManager.getAuthService}
  /// This method has to be overridden to give the authentication service to use
  /// {@endtemplate}
  @protected
  Future<MixinAuthService> getAuthService();

  /// {@template act_shared_auth.AbsAuthManager.getStorageService}
  /// This method has to be overridden to give the auth storage service to use
  /// {@endtemplate}
  @protected
  Future<MixinAuthStorageService?> getStorageService() async => null;

  /// {@template act_shared_auth.AbsAuthManager.onAuthStatusUpdated}
  /// Called when the current [AuthStatus] linked to [authService] is updated.
  ///
  /// Can be overridden in the derived class, to have the updated information.
  /// {@endtemplate}
  @protected
  Future<void> onAuthStatusUpdated(AuthStatus status) async {}

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await _authStatusSub.cancel();
    return super.disposeLifeCycle();
  }
}
