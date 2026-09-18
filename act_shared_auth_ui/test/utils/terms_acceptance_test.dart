// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth_ui/act_shared_auth_ui.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_terms_ui.dart';

void main() {
  // `readTermsAcceptedAt` goes through `JwtParserUtility`, which logs through the logger of the
  // application when a token cannot be parsed. Without a global manager that shortcut throws.
  setUpAll(FakeGlobalManager.install);

  final published = DateTime.utc(2026, 9, 16);

  group("readTermsAcceptedAt", () {
    test("reads the claim as a date, seconds since the epoch", () {
      final accepted = DateTime.utc(2026, 9, 16, 12, 30);

      final read = readTermsAcceptedAt(fakeAcceptanceToken(accepted));

      expect(read, accepted);
    });

    test("reads the claim when the server sends it as a string", () {
      final read = readTermsAcceptedAt(fakeIdpToken({termsAcceptedAtClaim: "1758024000"}));

      expect(read, DateTime.fromMillisecondsSinceEpoch(1758024000 * 1000, isUtc: true));
    });

    test("reads the claim the application names", () {
      final accepted = DateTime.utc(2026, 9, 16, 12, 30);

      final read = readTermsAcceptedAt(
        fakeIdpToken({"cgu_at": accepted.millisecondsSinceEpoch ~/ 1000}),
        claim: "cgu_at",
      );

      expect(read, accepted);
    });

    test("answers null on a token carrying no acceptance", () {
      expect(readTermsAcceptedAt(fakeIdpToken({"sub": "1234"})), isNull);
    });

    test("answers null on something which is not a token", () {
      expect(readTermsAcceptedAt("not-a-token"), isNull);
    });
  });

  group("areTermsStale", () {
    test("an acceptance older than the text in force is stale", () {
      expect(areTermsStale(acceptedAt: DateTime.utc(2026, 7), publishedAt: published), isTrue);
    });

    test("an acceptance of the very day the text was published holds", () {
      expect(areTermsStale(acceptedAt: published, publishedAt: published), isFalse);
    });

    test("a later acceptance holds", () {
      expect(areTermsStale(acceptedAt: DateTime.utc(2026, 10), publishedAt: published), isFalse);
    });

    test("an account which never accepted has to accept", () {
      expect(areTermsStale(acceptedAt: null, publishedAt: published), isTrue);
    });

    test("nothing is imposed when the date of the text in force is unknown", () {
      // A missing or unreadable configuration must not lock every user out of the application.
      expect(areTermsStale(acceptedAt: null, publishedAt: null), isFalse);
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

    test("lets an account whose acceptance is up to date through", () {
      final redirect = resolveTermsRedirect(
        mustAcceptTerms: false,
        route: FakeTermsRoute.home,
        termsRoute: FakeTermsRoute.terms,
      );

      expect(redirect, isNull);
    });
  });
}
