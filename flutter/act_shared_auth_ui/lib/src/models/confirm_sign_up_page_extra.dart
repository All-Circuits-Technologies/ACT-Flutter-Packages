// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_shared_auth_ui/src/models/sign_up_page_extra.dart';

/// This model can be used to pass information to the confirm-sign-up views when going to those
/// views with the router manager
///
/// In this subclass of [SignUpPageExtra], inherited [accountId] is made mandatory and not null.
class ConfirmSignUpPageExtra<T extends MixinRoute> extends SignUpPageExtra<T> {
  /// Class constructor
  const ConfirmSignUpPageExtra({
    required String super.accountId,
    super.password,
    super.nextRouteWhenSuccess,
    super.previousError,
  });
}
