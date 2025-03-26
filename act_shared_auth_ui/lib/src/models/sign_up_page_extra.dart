// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_ui/src/models/abs_auth_page_extra.dart';

/// This model can be used to pass information to the sign-up views when going to those views
/// with the router manager
class SignUpPageExtra<T extends MixinRoute> extends AbsAuthPageExtra<T, AuthSignUpStatus> {
  /// Account identifier
  ///
  /// Likely optional when joining self sign up procedure pages, in which case a non-null value can
  /// be used to pre-fill an input field.
  /// Likely mandatory for subsequent pages of the self sign-up process in order to track account
  /// being created, see `ConfirmSignUpPageExtra` subclass.
  final String? accountId;

  /// Account password
  ///
  /// Optional when joining self sign up procedure pages, it may be used to pre-fill a form if
  /// joined from a filled sign in page for example (after a no such account error typically).
  ///
  /// Optional for subsequent pages, may be useful to silently sign user in after account is created
  /// if auth backend do not auto-sign-in newly created accounts.
  final String? password;

  /// Class constructor
  const SignUpPageExtra({
    this.accountId,
    this.password,
    super.nextRouteWhenSuccess,
    super.previousError,
  });

  /// Equatable properties
  @override
  List<Object?> get props => super.props + [accountId, password];
}
