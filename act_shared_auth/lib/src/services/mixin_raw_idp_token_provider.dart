// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/src/services/mixin_auth_service.dart';

/// This mixin is used by the authentication services backed by an identity provider, to hand out
/// the raw access token that provider delivered.
///
/// [MixinAuthService] already gives the tokens an application signs its calls with; this one is
/// about the claims an application reads itself, such as the date an account accepted the terms:
/// the identity provider stamps them on the token, and the application is what decides what to do
/// with them.
///
/// A service which only speaks to its own backend doesn't mix this in: an application then knows
/// that no claim of an identity provider is to be read.
mixin MixinRawIdpTokenProvider on MixinAuthService {
  /// {@template act_shared_auth.MixinRawIdpTokenProvider.getIdpAccessToken}
  /// Get the raw access token delivered by the identity provider.
  ///
  /// Returns null when no user is signed in, or when the token can't be obtained.
  /// {@endtemplate}
  Future<String?> getIdpAccessToken();
}
