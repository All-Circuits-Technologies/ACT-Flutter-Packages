// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("AuthPropertyStatus", () {
    test("holds the finished change and the one to confirm for successes", () {
      final successes = AuthPropertyStatus.values.where((status) => status.isSuccess);

      expect(successes, [AuthPropertyStatus.confirmWithCode, AuthPropertyStatus.done]);
    });

    test("holds every status which is not a success for an error", () {
      expect(AuthPropertyStatus.badArgument.isError, isTrue);
      expect(AuthPropertyStatus.done.isError, isFalse);
    });

    test("asks the user to act when the change cannot go on without them", () {
      final toAct = AuthPropertyStatus.values.where((status) => status.userNeedsToAct);

      expect(toAct, [
        AuthPropertyStatus.confirmWithCode,
        AuthPropertyStatus.accountPropertyConflict,
        AuthPropertyStatus.wrongConfirmationCode,
      ]);
    });
  });
}
