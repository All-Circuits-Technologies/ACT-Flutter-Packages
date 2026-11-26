// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("AuthResetPwdStatus", () {
    test("holds the finished reset for the only success", () {
      final successes = AuthResetPwdStatus.values.where((status) => status.isSuccess);

      expect(successes, [AuthResetPwdStatus.done]);
    });

    test("waits for the user when the reset has to be confirmed by a code", () {
      final waiting = AuthResetPwdStatus.values.where((status) => status.userNeedsToAct);

      expect(waiting, [AuthResetPwdStatus.confirmResetPasswordWithCode]);
    });

    test("holds neither the finished reset nor the awaited code for an error", () {
      expect(AuthResetPwdStatus.done.isError, isFalse);
      expect(AuthResetPwdStatus.confirmResetPasswordWithCode.isError, isFalse);
      expect(AuthResetPwdStatus.genericError.isError, isTrue);
    });
  });
}
