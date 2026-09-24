// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_tb_extender_auth/act_tb_extender_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("BrokerAuthError.fromCode", () {
    /// The code of the documented contract, and the error each one is read as.
    const codes = {
      "invalid_request": BrokerAuthError.invalidRequest,
      "invalid_token": BrokerAuthError.invalidToken,
      "invalid_audience": BrokerAuthError.invalidAudience,
      "email_not_verified": BrokerAuthError.emailNotVerified,
      "provisioning_conflict": BrokerAuthError.provisioningConflict,
      "thingsboard_unavailable": BrokerAuthError.thingsboardUnavailable,
      "keycloak_unavailable": BrokerAuthError.keycloakUnavailable,
      "internal_error": BrokerAuthError.internalError,
      "reauth_required": BrokerAuthError.reauthRequired,
      "release_refused": BrokerAuthError.releaseRefused,
      "claim_refused": BrokerAuthError.claimRefused,
      "terms_outdated": BrokerAuthError.termsOutdated,
      "terms_source_unavailable": BrokerAuthError.termsSourceUnavailable,
      "not_configured": BrokerAuthError.notConfigured,
    };

    for (final entry in codes.entries) {
      test("reads ${entry.key} as ${entry.value.name}", () {
        expect(BrokerAuthError.fromCode(entry.key), entry.value);
      });
    }

    test("reads a code which isn't documented as unknown", () {
      expect(BrokerAuthError.fromCode("teapot"), BrokerAuthError.unknown);
    });

    test("reads an answer without any code as unknown", () {
      expect(BrokerAuthError.fromCode(null), BrokerAuthError.unknown);
    });
  });
}
