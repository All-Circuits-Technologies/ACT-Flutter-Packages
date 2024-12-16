// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_ui/src/models/abs_auth_page_extra.dart';

/// This model can be used to pass information to the sign in views when going to those views with
/// the router manager
class SignInPageExtra<T extends MixinRoute>
    extends AbsAuthPageExtra<T, AuthSignInStatus> {
  /// Class constructor
  const SignInPageExtra({
    super.nextRouteWhenSuccess,
    super.previousError,
  });
}
