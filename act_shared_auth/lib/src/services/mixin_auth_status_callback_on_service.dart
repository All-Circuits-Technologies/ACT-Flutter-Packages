// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

/// {@macro act_shared_auth.MixinAuthStatusCallback.presentation}
///
/// This mixin is used to add the [MixinAuthStatusCallback] functionality to a service that extends
/// [AbsWithLifeCycle].
mixin MixinAuthStatusCallbackOnService<AuthManager extends AbsAuthManager>
    on AbsWithLifeCycle, MixinAuthStatusCallback<AuthManager> {
  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    await initUpdate();
  }

  /// {@macro act_foundation.MixinWithLifeCycleDispose.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await disposeUpdate();

    return super.disposeLifeCycle();
  }
}
