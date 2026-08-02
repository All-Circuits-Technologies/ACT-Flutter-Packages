// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("AuthSignInStatus", () {
    test("holds the finished sign in for the only success", () {
      final successes = AuthSignInStatus.values.where((status) => status.isSuccess);

      expect(successes, [AuthSignInStatus.done]);
    });

    test("tells the statuses which wait for the user from the errors", () {
      final waiting = AuthSignInStatus.values.where((status) => status.userNeedsToAct);

      expect(waiting.every((status) => !status.isError), isTrue);
    });

    test("asks the user to act when the sign in cannot go on without them", () {
      final waiting = AuthSignInStatus.values.where((status) => status.userNeedsToAct);

      expect(waiting, [
        AuthSignInStatus.confirmSignInWithNewPassword,
        AuthSignInStatus.resetPassword,
        AuthSignInStatus.confirmSignUp,
      ]);
    });
  });
}
