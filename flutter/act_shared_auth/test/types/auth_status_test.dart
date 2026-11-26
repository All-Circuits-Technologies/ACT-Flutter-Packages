// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("AuthStatus.isSignedIn", () {
    test("holds a user who signed in for signed in", () {
      expect(AuthStatus.signedIn.isSignedIn, isTrue);
    });

    test("holds every other status for signed out", () {
      final signedIn = AuthStatus.values.where((status) => status.isSignedIn);

      expect(signedIn, [AuthStatus.signedIn]);
    });
  });
}
