// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("AuthDeleteStatus", () {
    test("holds the deleted account for a success", () {
      final successes = AuthDeleteStatus.values.where((status) => status.isSuccess);

      expect(successes, [AuthDeleteStatus.done]);
    });

    test("holds every status which is not a success for an error", () {
      final errors = AuthDeleteStatus.values.where((status) => status.isError);

      expect(errors, [AuthDeleteStatus.networkError, AuthDeleteStatus.genericError]);
    });
  });
}
