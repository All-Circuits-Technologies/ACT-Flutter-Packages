// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_ui/src/models/abs_auth_page_extra.dart';

/// This model can be used to pass information to the reset password views when going to those views
/// with the router manager
class ResetPwdPageExtra<T extends MixinRoute>
    extends AbsAuthPageExtra<T, AuthResetPwdStatus> {
  /// The username to use to update the forgotten password
  final String username;

  /// The confirmation code received by mail or other, to confirm the password resetting.
  final String? confirmationCode;

  /// Class constructor
  const ResetPwdPageExtra({
    required this.username,
    this.confirmationCode,
    super.nextRouteWhenSuccess,
    super.previousError,
  });

  /// Class properties
  @override
  List<Object?> get props => [
        username,
        confirmationCode,
        ...super.props,
      ];
}
