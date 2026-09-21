// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth_ui/act_shared_auth_ui.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_terms_ui.dart';

void main() {
  // `readTermsAcceptedVersion` goes through `JwtParserUtility`, which logs through the logger of
  // the application when a token cannot be parsed. Without a global manager that shortcut throws.
  setUpAll(FakeGlobalManager.install);

  group("readTermsAcceptedVersion", () {
    test("reads the version claim as it is", () {
      final token = fakeIdpToken({termsAcceptedVersionClaim: "2026-09-16"});

      expect(readTermsAcceptedVersion(token), "2026-09-16");
    });

    test("trims the claim and answers null when it is blank", () {
      expect(readTermsAcceptedVersion(fakeIdpToken({termsAcceptedVersionClaim: "  v3 "})), "v3");
      expect(readTermsAcceptedVersion(fakeIdpToken({termsAcceptedVersionClaim: "   "})), isNull);
    });

    test("answers null when the claim is missing or the token unreadable", () {
      expect(readTermsAcceptedVersion(fakeIdpToken({"sub": "1234"})), isNull);
      expect(readTermsAcceptedVersion("not-a-token"), isNull);
    });

    test("reads another claim name when the application says so", () {
      expect(readTermsAcceptedVersion(fakeIdpToken({"tos": "v1"}), claim: "tos"), "v1");
    });
  });

  group("resolveTermsRedirect", () {
    test("imposes the terms page on a page which needs accepted terms", () {
      final redirect = resolveTermsRedirect(
        mustAcceptTerms: true,
        route: FakeTermsRoute.home,
        termsRoute: FakeTermsRoute.terms,
      );

      expect(redirect, FakeTermsRoute.terms);
    });

    test("lets a page which needs no accepted terms through", () {
      final redirect = resolveTermsRedirect(
        mustAcceptTerms: true,
        route: FakeTermsRoute.about,
        termsRoute: FakeTermsRoute.terms,
      );

      expect(redirect, isNull);
    });

    test("lets the terms page itself through", () {
      final redirect = resolveTermsRedirect(
        mustAcceptTerms: true,
        route: FakeTermsRoute.terms,
        termsRoute: FakeTermsRoute.terms,
      );

      expect(redirect, isNull);
    });

    test("lets an account which has nothing to accept through", () {
      final redirect = resolveTermsRedirect(
        mustAcceptTerms: false,
        route: FakeTermsRoute.home,
        termsRoute: FakeTermsRoute.terms,
      );

      expect(redirect, isNull);
    });
  });
}
