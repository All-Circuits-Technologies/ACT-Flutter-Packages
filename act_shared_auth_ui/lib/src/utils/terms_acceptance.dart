// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:act_shared_auth_ui/src/types/mixin_terms_route.dart';

/// The claim of the identity provider token which names the version of the terms the account
/// accepted.
///
/// Another identity provider names it the way it wants, which is what the `claim` parameter of
/// [readTermsAcceptedVersion] is for.
const termsAcceptedVersionClaim = "terms_accepted_version";

/// Read, in the raw token of the identity provider, the version of the terms the account accepted.
///
/// Answers null when the token can't be parsed, when the claim is missing, or when it is blank:
/// the account never accepted anything the application can compare with.
///
/// The token is deliberately not verified here: the server does that on every call it receives,
/// and this value only decides whether a screen is displayed. A user editing their own token would
/// only be hiding their own acceptance screen, and the next refresh puts it back.
String? readTermsAcceptedVersion(String rawIdpToken, {String claim = termsAcceptedVersionClaim}) {
  final payload = JwtParserUtility.tryToParseToken(rawIdpToken)?.payload;

  if (payload is! Map) {
    return null;
  }

  final raw = payload[claim];

  if (raw == null) {
    return null;
  }

  final version = "$raw".trim();

  return version.isEmpty ? null : version;
}

/// Pure decision function of the terms router guard.
///
/// Given whether the terms in force are still to be accepted ([mustAcceptTerms]) and the [route]
/// the router wants to display, it returns [termsRoute] when that page must be displayed first, and
/// null when the navigation is allowed as is.
///
/// The routes whose [MixinTermsRoute.needsAcceptedTerms] is false are never redirected: the sign in
/// page and the transient pages come before this guard, and the terms page itself must be
/// reachable.
///
/// This function is intentionally free of any dependency so that it can be unit tested in
/// isolation.
T? resolveTermsRedirect<T extends MixinTermsRoute>({
  required bool mustAcceptTerms,
  required T route,
  required T termsRoute,
}) {
  if (!mustAcceptTerms || !route.needsAcceptedTerms) {
    return null;
  }

  return termsRoute;
}
