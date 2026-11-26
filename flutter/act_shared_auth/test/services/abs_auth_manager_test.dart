// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth.dart';

void main() {
  late FakeAuthService service;

  setUp(() {
    FakeGlobalManager.install();
    service = FakeAuthService();
  });

  tearDown(() => service.close());

  /// Builds the authentication manager of an application, and initializes it.
  Future<FakeAuthManager> aManager({MixinAuthStorageService? storage}) async {
    final manager = FakeAuthManager(service: service, storage: storage);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("AbsAuthBuilder", () {
    test("depends on the logger manager", () {
      final builder = FakeAuthBuilder(() => FakeAuthManager(service: service));

      expect(builder.dependsOn(), [LoggerManager]);
    });
  });

  group("AbsAuthManager.initLifeCycle", () {
    test("keeps the service the application signs its users in through", () async {
      final manager = await aManager();

      expect(manager.authService, service);
    });

    test("keeps the storage the application was built with", () async {
      final storage = FakeAuthStorageService();

      final manager = await aManager(storage: storage);

      expect(manager.storageService, storage);
    });

    test("hands the storage to the service", () async {
      final storage = FakeAuthStorageService();

      await aManager(storage: storage);

      expect(service.storageService, storage);
    });

    test("hands no storage to the service of an application which keeps nothing", () async {
      final manager = await aManager();

      expect(manager.storageService, isNull);
      expect(service.calls, isEmpty);
    });

    test("is told when the user signs in", () async {
      final manager = await aManager();

      service.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(manager.statuses, [AuthStatus.signedIn]);
    });

    test("is told every time the status of the user changes", () async {
      final manager = await aManager();

      service.updateStatus(AuthStatus.signedIn);
      service.updateStatus(AuthStatus.sessionExpired);
      await pumpEventQueue();

      expect(manager.statuses, [AuthStatus.signedIn, AuthStatus.sessionExpired]);
    });
  });

  group("AbsAuthManager.disposeLifeCycle", () {
    test("stops following the status of the user", () async {
      final manager = await aManager();

      await manager.disposeLifeCycle();
      service.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(manager.statuses, isEmpty);
    });
  });
}
