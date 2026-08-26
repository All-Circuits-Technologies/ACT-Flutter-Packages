// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth.dart';

/// A service of an application which follows the status of the user over its own life cycle.
class _Service extends AbsWithLifeCycle
    with
        MixinAuthStatusCallback<FakeAuthManager>,
        MixinAuthStatusCallbackOnService<FakeAuthManager> {
  /// The statuses the service was told about, in the order it was told.
  final List<AuthStatus> statuses = [];

  /// {@macro act_shared_auth.MixinAuthStatusCallback.onAuthStatusUpdated}
  @override
  Future<void> onAuthStatusUpdated(AuthStatus status) async {
    await super.onAuthStatusUpdated(status);

    statuses.add(status);
  }
}

void main() {
  late FakeGlobalManager globalManager;
  late FakeAuthService service;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    await service.close();
    await globalManager.reset();
  });

  /// Registers the authentication manager of an application, and builds a service of it.
  Future<_Service> aService() async {
    service = FakeAuthService();
    final manager = FakeAuthManager(service: service);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);
    globalManager.managers.registerSingleton<FakeAuthManager>(manager);

    final watcher = _Service();
    await watcher.initLifeCycle();

    return watcher;
  }

  group("MixinAuthStatusCallbackOnService", () {
    test("follows the status of the user as soon as the service is initialized", () async {
      final watcher = await aService();
      addTearDown(watcher.disposeLifeCycle);

      service.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(watcher.statuses, [AuthStatus.signedIn]);
    });

    test("stops following the status of the user once the service is disposed", () async {
      final watcher = await aService();

      await watcher.disposeLifeCycle();
      service.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(watcher.statuses, isEmpty);
    });
  });
}
