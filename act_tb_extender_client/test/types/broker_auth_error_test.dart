// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_tb_extender_client/act_tb_extender_client.dart';
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

    test("reads the names of the members without a broker code as unknown", () {
      expect(BrokerAuthError.fromCode("success"), BrokerAuthError.unknown);
      expect(BrokerAuthError.fromCode("network"), BrokerAuthError.unknown);
      expect(BrokerAuthError.fromCode("unknown"), BrokerAuthError.unknown);
    });

    test("reads an answer without any code as unknown", () {
      expect(BrokerAuthError.fromCode(null), BrokerAuthError.unknown);
    });
  });

  group("BrokerAuthError as a result status", () {
    test("is a success only for success", () {
      for (final status in BrokerAuthError.values) {
        expect(status.isSuccess, status == BrokerAuthError.success, reason: status.name);
      }
    });

    test("can be retried only after a failure which may not happen again", () {
      final retryable = BrokerAuthError.values.where((status) => status.canBeRetried).toSet();

      expect(retryable, {
        BrokerAuthError.thingsboardUnavailable,
        BrokerAuthError.keycloakUnavailable,
        BrokerAuthError.termsSourceUnavailable,
        BrokerAuthError.internalError,
        BrokerAuthError.network,
      });
    });
  });
}
