// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("AuthSignUpStatus", () {
    test("holds the finished sign up and the one to confirm for successes", () {
      final successes = AuthSignUpStatus.values.where((status) => status.isSuccess);

      expect(successes, [AuthSignUpStatus.confirmSignUpWithCode, AuthSignUpStatus.done]);
    });

    test("holds every status which is not a success for an error", () {
      expect(AuthSignUpStatus.genericError.isError, isTrue);
      expect(AuthSignUpStatus.done.isError, isFalse);
    });

    test("asks the user to act when the sign up cannot go on without them", () {
      final toAct = AuthSignUpStatus.values.where((status) => status.userNeedsToAct);

      expect(toAct, [
        AuthSignUpStatus.confirmSignUpWithCode,
        AuthSignUpStatus.accountIdentifierConflict,
        AuthSignUpStatus.accountPropertyConflict,
        AuthSignUpStatus.passwordNotConform,
        AuthSignUpStatus.wrongConfirmationCode,
      ]);
    });
  });
}
