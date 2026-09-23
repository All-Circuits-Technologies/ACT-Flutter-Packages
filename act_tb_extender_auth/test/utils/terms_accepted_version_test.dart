// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_tb_extender_auth/act_tb_extender_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_tb_extender_app.dart';

void main() {
  // The parsing logs through the logger of the application when a token can't be read
  setUpAll(FakeGlobalManager.install);

  group("readTermsAcceptedVersion", () {
    test("reads the version claim as it is", () {
      final token = fakeJwt({termsAcceptedVersionClaim: "2026-09-16"});

      expect(readTermsAcceptedVersion(token), "2026-09-16");
    });

    test("trims the claim and answers null when it is blank", () {
      expect(readTermsAcceptedVersion(fakeJwt({termsAcceptedVersionClaim: "  v3 "})), "v3");
      expect(readTermsAcceptedVersion(fakeJwt({termsAcceptedVersionClaim: "   "})), isNull);
    });

    test("answers null when the claim is missing or the token unreadable", () {
      expect(readTermsAcceptedVersion(fakeJwt({"sub": "1234"})), isNull);
      expect(readTermsAcceptedVersion("not-a-token"), isNull);
    });

    test("reads another claim name when the application says so", () {
      expect(readTermsAcceptedVersion(fakeJwt({"tos": "v1"}), claim: "tos"), "v1");
    });
  });
}
