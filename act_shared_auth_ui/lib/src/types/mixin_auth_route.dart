// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';

/// This mixin extends [MixinRoute] and adds the [isAuthNeeded] getter, used to know if a view needs
/// the user to be authenticated, or not.
mixin MixinAuthRoute on MixinRoute {
  /// {@template act_shared_auth_ui.MixinAuthRoute.isAuthNeeded}
  /// True if the authentication is needed
  /// {@endtemplate}
  bool get isAuthNeeded;
}
