// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The uniform error codes answered by the tb-extender auth broker.
///
/// The broker answers its errors with the shape `{"error": <code>, "message": ...}`. This enum
/// maps every documented `<code>`, plus the transport failures which never reach it, to a typed
/// value, and says whether calling it again with the same input may succeed later ([retryable]).
enum BrokerAuthError {
  /// HTTP 401 `invalid_token`: the Keycloak access token is missing, malformed or refused.
  invalidToken(retryable: false),

  /// HTTP 403 `invalid_audience`: the Keycloak token wasn't minted for the audience of the broker.
  invalidAudience(retryable: false),

  /// HTTP 403 `email_not_verified`: the email of the Keycloak account isn't verified yet.
  emailNotVerified(retryable: false),

  /// HTTP 409 `provisioning_conflict`: the ThingsBoard user couldn't be provisioned unambiguously.
  provisioningConflict(retryable: false),

  /// HTTP 502 `thingsboard_unavailable`: the broker couldn't reach ThingsBoard.
  thingsboardUnavailable(retryable: true),

  /// HTTP 502 `keycloak_unavailable`: the broker couldn't reach or command Keycloak.
  keycloakUnavailable(retryable: true),

  /// HTTP 501 `deletion_not_configured`: this broker tenant has no Keycloak Admin API access, so
  /// it can't delete an account at all.
  deletionNotConfigured(retryable: false),

  /// HTTP 500 `internal_error`: an unexpected error on the side of the broker.
  internalError(retryable: true),

  /// A transport failure: no HTTP answer at all, a timeout or a reset connection.
  network(retryable: true),

  /// The broker answered a status or a code which isn't part of the documented contract.
  unknown(retryable: false);

  /// Says whether calling the broker again with the same input may succeed later.
  final bool retryable;

  /// Class constructor
  const BrokerAuthError({required this.retryable});

  /// Map the `error` [code] of a broker answer to its [BrokerAuthError].
  ///
  /// A code which isn't documented, and a null one, are read as [BrokerAuthError.unknown].
  static BrokerAuthError fromCode(String? code) => switch (code) {
    "invalid_token" => BrokerAuthError.invalidToken,
    "invalid_audience" => BrokerAuthError.invalidAudience,
    "email_not_verified" => BrokerAuthError.emailNotVerified,
    "provisioning_conflict" => BrokerAuthError.provisioningConflict,
    "thingsboard_unavailable" => BrokerAuthError.thingsboardUnavailable,
    "keycloak_unavailable" => BrokerAuthError.keycloakUnavailable,
    "deletion_not_configured" => BrokerAuthError.deletionNotConfigured,
    "internal_error" => BrokerAuthError.internalError,
    _ => BrokerAuthError.unknown,
  };
}
