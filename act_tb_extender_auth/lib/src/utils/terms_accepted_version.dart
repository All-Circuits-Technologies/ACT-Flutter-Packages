// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_jwt_utilities/act_jwt_utilities.dart';

/// The claim of the Keycloak token which names the version of the terms the account accepted,
/// which the broker writes on the account when the terms are accepted.
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
