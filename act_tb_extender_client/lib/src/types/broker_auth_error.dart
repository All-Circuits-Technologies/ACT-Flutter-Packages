// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// The uniform error codes answered by the tb-extender auth broker.
///
/// The broker answers its errors with the shape `{"error": <code>, "message": ...}`. This enum
/// maps every documented `<code>`, plus the transport failures which never reach it, to a typed
/// value.
enum BrokerAuthError with MixinStringValueType {
  /// HTTP 400 `invalid_request`: the body of the call is missing a field or carries a blank one.
  invalidRequest(stringValueOverride: "invalid_request"),

  /// HTTP 401 `invalid_token`: the access token of the identity provider is missing, malformed
  /// or refused.
  invalidToken(stringValueOverride: "invalid_token"),

  /// HTTP 403 `invalid_audience`: the token of the identity provider wasn't minted for the
  /// audience of the broker.
  invalidAudience(stringValueOverride: "invalid_audience"),

  /// HTTP 403 `email_not_verified`: the email of the account of the identity provider isn't
  /// verified yet.
  emailNotVerified(stringValueOverride: "email_not_verified"),

  /// HTTP 403 `reauth_required`: the sign in behind the token is too old to delete the account;
  /// the user has to sign in again first.
  reauthRequired(stringValueOverride: "reauth_required"),

  /// HTTP 403 `release_refused`: the device to release is unknown, belongs to another customer, or
  /// the secret which comes with it is wrong.
  releaseRefused(stringValueOverride: "release_refused"),

  /// HTTP 403 `claim_refused`: the device to claim is unknown, or the secret which comes with it
  /// is wrong, missing or too old.
  claimRefused(stringValueOverride: "claim_refused"),

  /// HTTP 409 `provisioning_conflict`: the ThingsBoard user couldn't be provisioned unambiguously.
  provisioningConflict(stringValueOverride: "provisioning_conflict"),

  /// HTTP 502 `thingsboard_unavailable`: the broker couldn't reach ThingsBoard.
  thingsboardUnavailable(stringValueOverride: "thingsboard_unavailable"),

  /// HTTP 502 `keycloak_unavailable`: the broker couldn't reach or command the identity provider.
  keycloakUnavailable(stringValueOverride: "keycloak_unavailable"),

  /// HTTP 409 `terms_outdated`: the version of the terms accepted isn't the one in force.
  termsOutdated(stringValueOverride: "terms_outdated"),

  /// HTTP 502 `terms_source_unavailable`: the broker couldn't read the version of the terms in
  /// force.
  termsSourceUnavailable(stringValueOverride: "terms_source_unavailable"),

  /// HTTP 501 `not_configured`: this broker tenant lacks what the call needs, the access to the
  /// admin API of the identity provider or the source of the terms.
  notConfigured(stringValueOverride: "not_configured"),

  /// HTTP 500 `internal_error`: an unexpected error on the side of the broker.
  internalError(stringValueOverride: "internal_error"),

  /// A transport failure: no HTTP answer at all, a timeout or a reset connection.
  network(stringValueOverride: null),

  /// The broker answered a status or a code which isn't part of the documented contract.
  unknown(stringValueOverride: null);

  /// {@macro act_dart_utility.MixinStringValueType.stringValueOverride}
  @override
  final String? stringValueOverride;

  /// Class constructor
  const BrokerAuthError({required this.stringValueOverride});

  /// Map the `error` [code] of a broker answer to its [BrokerAuthError].
  ///
  /// A code which isn't documented, and a null one, are read as [BrokerAuthError.unknown].
  static BrokerAuthError fromCode(String? code) =>
      MixinStringValueType.tryToParseFromStringValue(value: code, values: _brokerCodes) ??
      BrokerAuthError.unknown;

  /// The members which are answered by the broker, [network] and [unknown] are not.
  static final _brokerCodes = values.where((error) => error.stringValueOverride != null).toList();
}
