// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_tb_extender_client/act_tb_extender_client.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_jwt.dart';

void main() {
  // The parsing logs through the logger of the application when a token can't be read
  setUpAll(FakeGlobalManager.install);

  group("readTermsAcceptedVersion", () {
    test("reads the version claim as it is", () {
      final token = fakeJwt({TermsAcceptedVersionUtility.termsAcceptedVersionClaim: "2026-09-16"});

      expect(TermsAcceptedVersionUtility.readTermsAcceptedVersion(token), "2026-09-16");
    });

    test("trims the claim and answers null when it is blank", () {
      expect(
        TermsAcceptedVersionUtility.readTermsAcceptedVersion(
          fakeJwt({TermsAcceptedVersionUtility.termsAcceptedVersionClaim: "  v3 "}),
        ),
        "v3",
      );
      expect(
        TermsAcceptedVersionUtility.readTermsAcceptedVersion(
          fakeJwt({TermsAcceptedVersionUtility.termsAcceptedVersionClaim: "   "}),
        ),
        isNull,
      );
    });

    test("answers null when the claim is missing or the token unreadable", () {
      expect(
        TermsAcceptedVersionUtility.readTermsAcceptedVersion(fakeJwt({"sub": "1234"})),
        isNull,
      );
      expect(TermsAcceptedVersionUtility.readTermsAcceptedVersion("not-a-token"), isNull);
    });

    test("reads another claim name when the application says so", () {
      expect(
        TermsAcceptedVersionUtility.readTermsAcceptedVersion(fakeJwt({"tos": "v1"}), claim: "tos"),
        "v1",
      );
    });
  });
}
