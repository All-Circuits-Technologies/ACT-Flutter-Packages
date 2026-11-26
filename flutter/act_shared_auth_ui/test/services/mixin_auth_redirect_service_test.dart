// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth_ui.dart';

void main() {
  late FakeAuthService auth;

  setUp(FakeGlobalManager.install);

  /// The redirection of an application whose user is signed in unless the test says otherwise.
  ///
  /// The page which is on top is [topView], which is what the redirection reads when the status of
  /// the user changes.
  Future<FakeAuthRedirectService> aRedirection({
    AuthStatus authStatus = AuthStatus.signedIn,
    FakeAuthRoute? topView,
    bool acceptRedirect = true,
  }) async {
    auth = FakeAuthService(authStatus: authStatus);
    addTearDown(auth.close);

    final authManager = FakeAuthManager(service: auth);
    await authManager.initLifeCycle();
    addTearDown(authManager.disposeLifeCycle);

    final router = FakeRouterManager(topView: topView)..acceptRedirect = acceptRedirect;

    final service = FakeAuthRedirectService(router: router, authManager: authManager);
    service.initAnswer = await service.init();
    addTearDown(service.close);

    return service;
  }

  group("MixinAuthRedirectService.initRedirectService", () {
    test("registers the redirection with the router of the application", () async {
      final service = await aRedirection();

      expect(service.router.registeredRedirects, 1);
    });

    test("stops when the router already has a redirection of its own", () async {
      final service = await aRedirection(acceptRedirect: false);

      expect(service.initAnswer, isFalse);
    });

    test("closes without a complaint a redirection which never started", () async {
      final service = await aRedirection(acceptRedirect: false);

      await expectLater(service.close(), completes);
    });
  });

  group("MixinAuthRedirectService.onRedirect", () {
    test("lets a signed in user read a page which needs a user", () async {
      final service = await aRedirection();

      expect(await service.askFor(FakeAuthRoute.profile), isNull);
    });

    test("sends a signed out user to the sign in page", () async {
      final service = await aRedirection(authStatus: AuthStatus.signedOut);

      expect(await service.askFor(FakeAuthRoute.profile), FakeAuthRoute.signIn);
    });

    test("lets a signed out user read a page which needs no user", () async {
      final service = await aRedirection(authStatus: AuthStatus.signedOut);

      expect(await service.askFor(FakeAuthRoute.about), isNull);
    });

    test("lets a signed out user reach the sign in page itself", () async {
      final service = await aRedirection(authStatus: AuthStatus.signedOut);

      expect(await service.askFor(FakeAuthRoute.signIn), isNull);
    });

    test("leaves the page the application itself asked for alone", () async {
      final service = await aRedirection(authStatus: AuthStatus.signedOut)
        ..ownAnswer = FakeAuthRoute.about;

      expect(await service.askFor(FakeAuthRoute.profile), FakeAuthRoute.about);
    });
  });

  group("MixinAuthRedirectService, the status of the user", () {
    test("sends the user of a page which needs one to the sign in page", () async {
      final service = await aRedirection(topView: FakeAuthRoute.profile);

      auth.updateStatus(AuthStatus.signedOut);
      await pumpEventQueue();

      expect(service.router.pushedFirst, [FakeAuthRoute.signIn]);
    });

    test("leaves the user of a page which needs none where it is", () async {
      final service = await aRedirection(topView: FakeAuthRoute.about);

      auth.updateStatus(AuthStatus.signedOut);
      await pumpEventQueue();

      expect(service.router.pushedFirst, isEmpty);
    });

    test("leaves a user who just signed in where it is", () async {
      final service = await aRedirection(
        authStatus: AuthStatus.signedOut,
        topView: FakeAuthRoute.profile,
      );

      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(service.router.pushedFirst, isEmpty);
    });

    test("sends the user away when the session expired", () async {
      final service = await aRedirection(topView: FakeAuthRoute.profile);

      auth.updateStatus(AuthStatus.sessionExpired);
      await pumpEventQueue();

      expect(service.router.pushedFirst, [FakeAuthRoute.signIn]);
    });

    test("does nothing for a status which did not change", () async {
      final service = await aRedirection(topView: FakeAuthRoute.profile);

      auth.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(service.router.pushedFirst, isEmpty);
    });

    test("stops following the user once the redirection is closed", () async {
      final service = await aRedirection(topView: FakeAuthRoute.profile);

      await service.close();
      auth.updateStatus(AuthStatus.signedOut);
      await pumpEventQueue();

      expect(service.router.pushedFirst, isEmpty);
    });
  });
}
