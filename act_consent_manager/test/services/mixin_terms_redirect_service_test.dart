// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_consent.dart';
import '../fakes/fake_terms_ui.dart';

/// What the user agreed to: every option, in the version [version].
ConsentDataModel<FakeOptions> _agreedTo(String version) => ConsentDataModel<FakeOptions>(
  version: version,
  options: ConsentOptionsModel<FakeOptions>.fromKeys(FakeOptions.values, ConsentStateEnum.accepted),
);

void main() {
  late FakeExternalLogger logs;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
  });

  /// The terms of an application whose version in force is "v2", the user having agreed to
  /// [agreedTo], or to nothing at all.
  FakeConsentService someTerms({
    String? agreedTo,
    ConsentLoadStatus versionStatus = ConsentLoadStatus.success,
  }) {
    final terms = FakeConsentService(
      logsHelper: logs.buildHelper(category: "terms"),
      versionStatus: versionStatus,
      userData: (agreedTo != null) ? _agreedTo(agreedTo) : null,
    );
    addTearDown(terms.disposeLifeCycle);

    return terms;
  }

  /// The redirection of an application whose terms are [terms] and which displays [topView].
  Future<FakeTermsRedirectService> aRedirection(
    FakeConsentService terms, {
    FakeTermsRoute? topView,
  }) async {
    final redirection = FakeTermsRedirectService(
      router: FakeTermsRouterManager(topView: topView),
      terms: terms,
    );
    await redirection.init();
    addTearDown(redirection.close);

    return redirection;
  }

  group("MixinTermsRedirectService.onRedirect", () {
    test("lets a page which needs no accepted terms through without loading them", () async {
      final terms = someTerms();
      final redirection = await aRedirection(terms);

      expect(await redirection.askFor(FakeTermsRoute.about), isNull);
      expect(await redirection.askFor(FakeTermsRoute.terms), isNull);
      expect(terms.userDataCalls, 0);
      expect(terms.latestVersionCalls, 0);
    });

    test("imposes the terms page while the user has not accepted the version in force", () async {
      final redirection = await aRedirection(someTerms(agreedTo: "v1"));

      expect(await redirection.askFor(FakeTermsRoute.home), FakeTermsRoute.terms);
    });

    test("lets a page through once the user accepted the version in force", () async {
      final redirection = await aRedirection(someTerms(agreedTo: "v2"));

      expect(await redirection.askFor(FakeTermsRoute.home), isNull);
    });

    test("imposes the terms page while it is not known where the terms stand", () async {
      final terms = someTerms(agreedTo: "v2", versionStatus: ConsentLoadStatus.failed);
      final redirection = await aRedirection(terms);

      expect(await redirection.askFor(FakeTermsRoute.home), FakeTermsRoute.terms);
      expect(terms.consentState, ConsentStateEnum.unknown);
    });
  });

  group("MixinTermsRedirectService, the state which changed", () {
    test("sends the user of a page which needs accepted terms to the terms page", () async {
      final terms = someTerms(agreedTo: "v1");
      final redirection = await aRedirection(terms, topView: FakeTermsRoute.home);

      await terms.loadAllConsentInfo();
      await pumpEventQueue();

      expect(redirection.router.replaced, [FakeTermsRoute.terms]);
    });

    test("leaves the user where it is once the terms are accepted", () async {
      final terms = someTerms(agreedTo: "v2");
      final redirection = await aRedirection(terms, topView: FakeTermsRoute.home);

      await terms.loadAllConsentInfo();
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("leaves the user of a page which needs no accepted terms where it is", () async {
      final terms = someTerms(agreedTo: "v1");
      final redirection = await aRedirection(terms, topView: FakeTermsRoute.about);

      await terms.loadAllConsentInfo();
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("sends the user to the terms page once when two changes come together", () async {
      final terms = someTerms(agreedTo: "v1");
      await terms.loadAllConsentInfo();
      final redirection = await aRedirection(terms, topView: FakeTermsRoute.home);

      // The first change is still being handled when the second one comes
      unawaited(terms.resetAllConsentInfo());
      unawaited(terms.loadAllConsentInfo());
      await pumpEventQueue();

      expect(redirection.router.replaced, [FakeTermsRoute.terms]);
    });

    test("stops following the terms once the redirection is closed", () async {
      final terms = someTerms(agreedTo: "v1");
      final redirection = await aRedirection(terms, topView: FakeTermsRoute.home);

      await redirection.close();
      await terms.loadAllConsentInfo();
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });
  });
}
