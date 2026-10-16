// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/src/services/mixin_auth_service.dart';

/// An authentication service which can record, on the account, that the user accepted the terms.
///
/// The version is the one the application displayed: the account then says which text was agreed
/// to, and the application compares it with the version in force to know whether to ask again.
///
/// A service which has nowhere to write that doesn't mix this in: an application then knows that
/// the acceptance has to be held somewhere else.
mixin MixinTermsAcceptor on MixinAuthService {
  /// {@template act_shared_auth.MixinTermsAcceptor.acceptTerms}
  /// Record that the user accepted the [version] of the terms.
  ///
  /// Answers true once the account carries it, false when it couldn't be recorded.
  /// {@endtemplate}
  Future<bool> acceptTerms({required String version});
}
