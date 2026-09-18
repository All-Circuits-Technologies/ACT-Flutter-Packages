// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:act_shared_auth_ui/src/types/mixin_terms_route.dart';

/// This is the default claim carrying the date the user accepted the terms, in seconds since the
/// epoch.
///
/// Keycloak stamps `terms_and_conditions` on the account when its TERMS_AND_CONDITIONS required
/// action is accepted; a protocol mapper of the client copies it into this claim. Another identity
/// provider names it the way it wants, which is what the `claim` parameter of [readTermsAcceptedAt]
/// is for.
const termsAcceptedAtClaim = "terms_accepted_at";

/// Read the date the user accepted the terms out of the [rawIdpToken], from its [claim].
///
/// Returns null when the token cannot be read or carries no acceptance — which is what an account
/// created before the terms existed looks like.
///
/// The token is deliberately not verified here: the server does that on every call it receives, and
/// this value only decides whether a screen is displayed. A user editing their own token would only
/// be hiding their own acceptance screen, and the next sign in puts it back.
DateTime? readTermsAcceptedAt(String rawIdpToken, {String claim = termsAcceptedAtClaim}) {
  final payload = JwtParserUtility.tryToParseToken(rawIdpToken)?.payload;

  if (payload is! Map) {
    return null;
  }

  final raw = payload[claim];
  final seconds = (raw is int) ? raw : int.tryParse("$raw");

  if (seconds == null) {
    return null;
  }

  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
}

/// Tell whether the terms have to be accepted again.
///
/// [acceptedAt] is what the account carries, [publishedAt] the date of the text in force. An
/// acceptance older than the text is not an acceptance of that text.
///
/// Nothing is imposed when the application does not know the date of the text in force: a missing
/// or unreadable configuration must not lock every user out of the application.
///
/// This function is intentionally free of any dependency so that it can be unit tested in
/// isolation.
bool areTermsStale({required DateTime? acceptedAt, required DateTime? publishedAt}) {
  if (publishedAt == null) {
    return false;
  }

  if (acceptedAt == null) {
    return true;
  }

  return acceptedAt.isBefore(publishedAt);
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
