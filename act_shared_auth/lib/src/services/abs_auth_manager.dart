// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/src/services/mixin_auth_service.dart';
import 'package:flutter/foundation.dart';

/// Builder of the [AbsAuthManager] manager
abstract class AbsAuthBuilder<T extends AbsAuthManager>
    extends ManagerBuilder<T> {
  /// Class constructor
  AbsAuthBuilder(super.factory);

  /// Abstract method which list the manager dependence on others managers
  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

/// This is the abstract manager for authentication
///
/// This manager is detached of the authentication provider thanks to the [MixinAuthService], which
/// allows to minimize the code refactoring when we want to change the provider.
abstract class AbsAuthManager extends AbstractManager {
  /// This is the authentication service to use in the application
  late final MixinAuthService authService;

  /// This method has to be overridden to give the authentication service to use
  @protected
  Future<MixinAuthService> getAuthService();

  /// Init the manager
  @override
  @mustCallSuper
  Future<void> initManager() async {
    authService = await getAuthService();
  }
}
