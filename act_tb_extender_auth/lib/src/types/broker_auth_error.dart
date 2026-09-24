// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The uniform error codes answered by the tb-extender auth broker.
///
/// The broker answers its errors with the shape `{"error": <code>, "message": ...}`. This enum
/// maps every documented `<code>`, plus the transport failures which never reach it, to a typed
/// value.
enum BrokerAuthError {
  /// HTTP 400 `invalid_request`: the body of the call is missing a field or carries a blank one.
  invalidRequest,

  /// HTTP 401 `invalid_token`: the Keycloak access token is missing, malformed or refused.
  invalidToken,

  /// HTTP 403 `invalid_audience`: the Keycloak token wasn't minted for the audience of the broker.
  invalidAudience,

  /// HTTP 403 `email_not_verified`: the email of the Keycloak account isn't verified yet.
  emailNotVerified,

  /// HTTP 403 `reauth_required`: the sign in behind the token is too old to delete the account;
  /// the user has to sign in again first.
  reauthRequired,

  /// HTTP 403 `release_refused`: the device to release is unknown, belongs to another customer, or
  /// the secret which comes with it is wrong.
  releaseRefused,

  /// HTTP 403 `claim_refused`: the device to claim is unknown, or the secret which comes with it
  /// is wrong, missing or too old.
  claimRefused,

  /// HTTP 409 `provisioning_conflict`: the ThingsBoard user couldn't be provisioned unambiguously.
  provisioningConflict,

  /// HTTP 502 `thingsboard_unavailable`: the broker couldn't reach ThingsBoard.
  thingsboardUnavailable,

  /// HTTP 502 `keycloak_unavailable`: the broker couldn't reach or command Keycloak.
  keycloakUnavailable,

  /// HTTP 409 `terms_outdated`: the version of the terms accepted isn't the one in force.
  termsOutdated,

  /// HTTP 502 `terms_source_unavailable`: the broker couldn't read the version of the terms in
  /// force.
  termsSourceUnavailable,

  /// HTTP 501 `not_configured`: this broker tenant lacks what the call needs, the Keycloak Admin
  /// API access or the source of the terms.
  notConfigured,

  /// HTTP 501 `deletion_not_configured`: this broker tenant has no Keycloak Admin API access, so
  /// it can't delete an account at all. A broker which answers [notConfigured] no longer answers
  /// this one.
  deletionNotConfigured,

  /// HTTP 501 `admin_not_configured`: this broker tenant has no Keycloak Admin API access, so it
  /// can't write anything on an account. A broker which answers [notConfigured] no longer answers
  /// this one.
  adminNotConfigured,

  /// HTTP 500 `internal_error`: an unexpected error on the side of the broker.
  internalError,

  /// A transport failure: no HTTP answer at all, a timeout or a reset connection.
  network,

  /// The broker answered a status or a code which isn't part of the documented contract.
  unknown;

  /// Map the `error` [code] of a broker answer to its [BrokerAuthError].
  ///
  /// A code which isn't documented, and a null one, are read as [BrokerAuthError.unknown].
  static BrokerAuthError fromCode(String? code) => switch (code) {
    "invalid_request" => BrokerAuthError.invalidRequest,
    "invalid_token" => BrokerAuthError.invalidToken,
    "invalid_audience" => BrokerAuthError.invalidAudience,
    "email_not_verified" => BrokerAuthError.emailNotVerified,
    "reauth_required" => BrokerAuthError.reauthRequired,
    "release_refused" => BrokerAuthError.releaseRefused,
    "claim_refused" => BrokerAuthError.claimRefused,
    "provisioning_conflict" => BrokerAuthError.provisioningConflict,
    "thingsboard_unavailable" => BrokerAuthError.thingsboardUnavailable,
    "keycloak_unavailable" => BrokerAuthError.keycloakUnavailable,
    "terms_outdated" => BrokerAuthError.termsOutdated,
    "terms_source_unavailable" => BrokerAuthError.termsSourceUnavailable,
    "not_configured" => BrokerAuthError.notConfigured,
    "deletion_not_configured" => BrokerAuthError.deletionNotConfigured,
    "admin_not_configured" => BrokerAuthError.adminNotConfigured,
    "internal_error" => BrokerAuthError.internalError,
    _ => BrokerAuthError.unknown,
  };
}
