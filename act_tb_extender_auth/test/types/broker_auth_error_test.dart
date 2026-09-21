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
      "deletion_not_configured": BrokerAuthError.deletionNotConfigured,
      "admin_not_configured": BrokerAuthError.adminNotConfigured,
      "internal_error": BrokerAuthError.internalError,
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

  group("BrokerAuthError.retryable", () {
    test("says that the errors which come from an unavailable side are worth another call", () {
      expect(BrokerAuthError.thingsboardUnavailable.retryable, isTrue);
      expect(BrokerAuthError.keycloakUnavailable.retryable, isTrue);
      expect(BrokerAuthError.internalError.retryable, isTrue);
      expect(BrokerAuthError.network.retryable, isTrue);
    });

    test("says that the errors which come from the account itself are not", () {
      expect(BrokerAuthError.invalidRequest.retryable, isFalse);
      expect(BrokerAuthError.invalidToken.retryable, isFalse);
      expect(BrokerAuthError.invalidAudience.retryable, isFalse);
      expect(BrokerAuthError.emailNotVerified.retryable, isFalse);
      expect(BrokerAuthError.provisioningConflict.retryable, isFalse);
      expect(BrokerAuthError.deletionNotConfigured.retryable, isFalse);
      expect(BrokerAuthError.adminNotConfigured.retryable, isFalse);
      expect(BrokerAuthError.unknown.retryable, isFalse);
    });
  });
}
