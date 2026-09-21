// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_terms_ui.dart';

void main() {
  setUp(FakeGlobalManager.install);

  /// The redirection of an application which answers [mustAccept] and displays [topView].
  Future<FakeTermsRedirectService> aRedirection({
    bool mustAccept = false,
    FakeTermsRoute? topView,
    bool withChanges = true,
  }) async {
    final redirection = FakeTermsRedirectService(
      router: FakeTermsRouterManager(topView: topView),
      mustAccept: mustAccept,
      withChanges: withChanges,
    );
    await redirection.init();
    addTearDown(redirection.close);
    addTearDown(redirection.changes.close);

    return redirection;
  }

  group("MixinTermsRedirectService.onRedirect", () {
    test("lets a page which needs no accepted terms through without asking", () async {
      final redirection = await aRedirection(mustAccept: true);

      expect(await redirection.askFor(FakeTermsRoute.about), isNull);
      expect(await redirection.askFor(FakeTermsRoute.terms), isNull);
      expect(redirection.mustAcceptCalls, 0);
    });

    test("imposes the terms page while the application says they have to be accepted", () async {
      final redirection = await aRedirection(mustAccept: true);

      expect(await redirection.askFor(FakeTermsRoute.home), FakeTermsRoute.terms);
      expect(redirection.mustAcceptCalls, 1);
    });

    test("lets a page through once the application says there is nothing to accept", () async {
      final redirection = await aRedirection();

      expect(await redirection.askFor(FakeTermsRoute.home), isNull);
      expect(redirection.mustAcceptCalls, 1);
    });
  });

  group("MixinTermsRedirectService, the answer which changed", () {
    test("sends the user of a page which needs accepted terms to the terms page", () async {
      final redirection = await aRedirection(mustAccept: true, topView: FakeTermsRoute.home);

      redirection.changes.add(null);
      await pumpEventQueue();

      expect(redirection.router.replaced, [FakeTermsRoute.terms]);
    });

    test("leaves the user where it is while there is nothing to accept", () async {
      final redirection = await aRedirection(topView: FakeTermsRoute.home);

      redirection.changes.add(null);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("leaves the user of a page which needs no accepted terms where it is", () async {
      final redirection = await aRedirection(mustAccept: true, topView: FakeTermsRoute.terms);

      redirection.changes.add(null);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
      expect(redirection.mustAcceptCalls, 0);
    });

    test("stops following the application once the redirection is closed", () async {
      final redirection = await aRedirection(mustAccept: true, topView: FakeTermsRoute.home);

      await redirection.close();
      redirection.changes.add(null);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("starts with no stream when the application hands none over", () async {
      final redirection = await aRedirection(
        mustAccept: true,
        topView: FakeTermsRoute.home,
        withChanges: false,
      );

      redirection.changes.add(null);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });
  });
}
