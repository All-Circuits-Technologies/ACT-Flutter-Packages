// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/foundation.dart';

/// {@template act_shared_auth.MixinAuthStatusCallback.presentation}
/// Manage listening on [authStatus] stream and call [onAuthStatusUpdated] when the value is updated
///
/// [initUpdate] has to be called at the start of the class to listen the stream update.
/// [disposeUpdate] has to be called at the end of class life to cancel the subscription on the
/// stream.
/// {@endtemplate}
mixin MixinAuthStatusCallback<AuthManager extends AbsAuthManager> {
  /// This is the subscription linked to the auth status stream
  late final StreamSubscription _authStatusSub;

  /// Get the current [AuthStatus]
  AuthStatus get authStatus => globalGetIt().get<AuthManager>().authService.authStatus;

  /// To call at the start of the class life to listen the stream update
  @protected
  Future<void> initUpdate() async {
    _authStatusSub =
        globalGetIt().get<AuthManager>().authService.authStatusStream.listen(onAuthStatusUpdated);
  }

  /// {@template act_shared_auth.MixinAuthStatusCallback.onAuthStatusUpdated}
  /// Called when the [AuthStatus] has been updated
  ///
  /// This can be overridden by derived class to be advertised on [AuthStatus] update
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> onAuthStatusUpdated(AuthStatus status) async {}

  /// To call at the end of class life to cancel the subscription on the stream
  @protected
  Future<void> disposeUpdate() async {
    await _authStatusSub.cancel();
  }
}
