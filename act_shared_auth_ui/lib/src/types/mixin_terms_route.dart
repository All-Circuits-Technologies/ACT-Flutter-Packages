// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_router_manager/act_router_manager.dart';

/// This mixin extends [MixinRoute] and adds the [needsAcceptedTerms] getter, used to know if a view
/// can only be read by a user who accepted the terms in force, or not.
mixin MixinTermsRoute on MixinRoute {
  /// {@template act_shared_auth_ui.MixinTermsRoute.needsAcceptedTerms}
  /// True if the accepted terms are needed
  ///
  /// The terms page itself answers false, otherwise the guard would impose it over and over; so do
  /// the pages which come before the terms in the life of a user, such as the sign in page.
  /// {@endtemplate}
  bool get needsAcceptedTerms;
}
