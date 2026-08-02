// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_auth.dart';

void main() {
  late FakeGlobalManager globalManager;
  late FakeAuthService service;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    await service.close();
    await globalManager.reset();
  });

  /// Registers the authentication manager of an application whose user is [status], and watches it.
  Future<AuthStreamObserver<FakeAuthManager>> anObserver({
    AuthStatus status = AuthStatus.signedOut,
  }) async {
    service = FakeAuthService(authStatus: status);
    final manager = FakeAuthManager(service: service);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);
    globalManager.managers.registerSingleton<FakeAuthManager>(manager);

    final observer = AuthStreamObserver<FakeAuthManager>();
    addTearDown(observer.dispose);

    return observer;
  }

  group("AuthStreamObserver", () {
    test("holds a user who is already signed in for valid", () async {
      final observer = await anObserver(status: AuthStatus.signedIn);

      expect(observer.isValid, isTrue);
    });

    test("holds a user who is signed out for invalid", () async {
      final observer = await anObserver();

      expect(observer.isValid, isFalse);
    });

    test("holds a user whose session expired for invalid", () async {
      final observer = await anObserver(status: AuthStatus.sessionExpired);

      expect(observer.isValid, isFalse);
    });

    test("tells the application when the user signs in", () async {
      final observer = await anObserver();
      final validities = <bool>[];
      final subscription = observer.stream.listen(validities.add);
      addTearDown(subscription.cancel);

      service.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(validities, [true]);
    });

    test("tells the application when the user signs out", () async {
      final observer = await anObserver(status: AuthStatus.signedIn);
      final validities = <bool>[];
      final subscription = observer.stream.listen(validities.add);
      addTearDown(subscription.cancel);

      service.updateStatus(AuthStatus.signedOut);
      await pumpEventQueue();

      expect(validities, [false]);
    });

    test("says nothing when the status changes without the user leaving", () async {
      final observer = await anObserver();
      final validities = <bool>[];
      final subscription = observer.stream.listen(validities.add);
      addTearDown(subscription.cancel);

      service.updateStatus(AuthStatus.sessionExpired);
      await pumpEventQueue();

      expect(validities, isEmpty);
    });
  });
}
