// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

/// {@macro act_shared_auth.MixinAuthStatusCallback.presentation}
///
/// This mixin is used to add the [MixinAuthStatusCallback] functionality to a service that extends
/// [AbsWithLifeCycle].
mixin MixinAuthStatusCallbackOnService<AuthManager extends AbsAuthManager>
    on AbsWithLifeCycle, MixinAuthStatusCallback<AuthManager> {
  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    await initUpdate();
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await disposeUpdate();

    return super.disposeLifeCycle();
  }
}
