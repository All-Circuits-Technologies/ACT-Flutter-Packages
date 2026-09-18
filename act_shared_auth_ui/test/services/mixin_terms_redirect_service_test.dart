// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_ui.dart';
import '../fakes/fake_terms_ui.dart';

void main() {
  late FakeAuthService auth;

  setUp(FakeGlobalManager.install);

  final published = DateTime.utc(2026, 9, 16);
  final staleToken = fakeAcceptanceToken(DateTime.utc(2026, 7));
  final freshToken = fakeAcceptanceToken(DateTime.utc(2026, 10));

  /// The redirection of an application whose authentication is [service].
  ///
  /// The page which is on top is [topView], which is what the redirection reads when the status of
  /// the user changes, and [termsPublishedAt] is what the configuration of the application says
  /// about the text in force.
  Future<FakeTermsRedirectService> aRedirection({
    required FakeAuthService service,
    FakeTermsRoute? topView,
    DateTime? termsPublishedAt,
  }) async {
    auth = service;
    addTearDown(auth.close);

    final authManager = FakeAuthManager(service: auth);
    await authManager.initLifeCycle();
    addTearDown(authManager.disposeLifeCycle);

    final redirection = FakeTermsRedirectService(
      router: FakeTermsRouterManager(topView: topView),
      authManager: authManager,
      termsPublishedAt: termsPublishedAt,
    );
    await redirection.init();
    addTearDown(redirection.close);

    return redirection;
  }

  /// The redirection of an application whose identity provider hands out [rawToken].
  Future<FakeTermsRedirectService> anIdpRedirection({
    String? rawToken,
    AuthStatus authStatus = AuthStatus.signedOut,
    FakeTermsRoute? topView,
    DateTime? termsPublishedAt,
  }) => aRedirection(
    service: FakeIdpAuthService(rawToken: rawToken, authStatus: authStatus),
    topView: topView,
    termsPublishedAt: termsPublishedAt,
  );

  group("MixinTermsRedirectService, the status of the user", () {
    test("sends a user whose acceptance is out of date to the terms page", () async {
      final redirection = await anIdpRedirection(
        rawToken: staleToken,
        topView: FakeTermsRoute.home,
        termsPublishedAt: published,
      );

      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(redirection.router.replaced, [FakeTermsRoute.terms]);
    });

    test("leaves a user whose acceptance is up to date where it is", () async {
      final redirection = await anIdpRedirection(
        rawToken: freshToken,
        topView: FakeTermsRoute.home,
        termsPublishedAt: published,
      );

      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("leaves the user of a page which needs no accepted terms where it is", () async {
      final redirection = await anIdpRedirection(
        rawToken: staleToken,
        topView: FakeTermsRoute.about,
        termsPublishedAt: published,
      );

      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("imposes nothing to a user who signed out", () async {
      final redirection = await anIdpRedirection(
        rawToken: staleToken,
        authStatus: AuthStatus.signedIn,
        topView: FakeTermsRoute.home,
        termsPublishedAt: published,
      );

      auth.updateStatus(AuthStatus.signedOut);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("imposes nothing when the authentication hands out no raw token", () async {
      final redirection = await aRedirection(
        service: FakeAuthService(authStatus: AuthStatus.signedOut),
        topView: FakeTermsRoute.home,
        termsPublishedAt: published,
      );

      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("imposes nothing when the date of the text in force is unknown", () async {
      final redirection = await anIdpRedirection(
        rawToken: staleToken,
        topView: FakeTermsRoute.home,
      );

      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("imposes nothing when the session hands out no token", () async {
      final redirection = await anIdpRedirection(
        topView: FakeTermsRoute.home,
        termsPublishedAt: published,
      );

      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });

    test("stops following the user once the redirection is closed", () async {
      final redirection = await anIdpRedirection(
        rawToken: staleToken,
        topView: FakeTermsRoute.home,
        termsPublishedAt: published,
      );

      await redirection.close();
      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(redirection.router.replaced, isEmpty);
    });
  });

  group("MixinTermsRedirectService.onRedirect", () {
    /// The redirection of an application whose user is signed in with [rawToken].
    Future<FakeTermsRedirectService> aSignedInRedirection({
      String? rawToken,
      DateTime? termsPublishedAt,
    }) => anIdpRedirection(
      rawToken: rawToken,
      authStatus: AuthStatus.signedIn,
      termsPublishedAt: termsPublishedAt,
    );

    test("imposes the terms page on a page which needs accepted terms", () async {
      final redirection = await aSignedInRedirection(
        rawToken: staleToken,
        termsPublishedAt: published,
      );

      expect(await redirection.askFor(FakeTermsRoute.home), FakeTermsRoute.terms);
    });

    test("lets the terms page itself through", () async {
      final redirection = await aSignedInRedirection(
        rawToken: staleToken,
        termsPublishedAt: published,
      );

      expect(await redirection.askFor(FakeTermsRoute.terms), isNull);
    });

    test("lets a page which needs no accepted terms through", () async {
      final redirection = await aSignedInRedirection(
        rawToken: staleToken,
        termsPublishedAt: published,
      );

      expect(await redirection.askFor(FakeTermsRoute.about), isNull);
    });

    test("lets an acceptance which is up to date through", () async {
      final redirection = await aSignedInRedirection(
        rawToken: freshToken,
        termsPublishedAt: published,
      );

      expect(await redirection.askFor(FakeTermsRoute.home), isNull);
    });

    test("imposes nothing to a user who is not signed in", () async {
      final redirection = await anIdpRedirection(
        rawToken: staleToken,
        termsPublishedAt: published,
      );

      expect(await redirection.askFor(FakeTermsRoute.home), isNull);
    });

    test("imposes nothing when the authentication hands out no raw token", () async {
      final redirection = await aRedirection(
        service: FakeAuthService(),
        termsPublishedAt: published,
      );

      expect(await redirection.askFor(FakeTermsRoute.home), isNull);
    });

    test("imposes nothing when the date of the text in force is unknown", () async {
      final redirection = await aSignedInRedirection(rawToken: staleToken);

      expect(await redirection.askFor(FakeTermsRoute.home), isNull);
    });
  });
}
