// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_auth.dart';

/// A class of an application which follows the status of the user.
class _Watcher with MixinAuthStatusCallback<FakeAuthManager> {
  /// The statuses the class was told about, in the order it was told.
  final List<AuthStatus> statuses = [];

  /// Starts following the status of the user.
  Future<void> start() => initUpdate();

  /// Stops following the status of the user.
  Future<void> stop() => disposeUpdate();

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

  /// Registers the authentication manager of an application whose user is [status].
  Future<void> anApplication({AuthStatus status = AuthStatus.signedOut}) async {
    service = FakeAuthService(authStatus: status);
    final manager = FakeAuthManager(service: service);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);
    globalManager.managers.registerSingleton<FakeAuthManager>(manager);
  }

  group("MixinAuthStatusCallback.authStatus", () {
    test("answers with the status the manager of the application knows", () async {
      await anApplication(status: AuthStatus.signedIn);

      expect(_Watcher().authStatus, AuthStatus.signedIn);
    });
  });

  group("MixinAuthStatusCallback.initUpdate", () {
    test("is told when the status of the user changes", () async {
      await anApplication();
      final watcher = _Watcher();
      await watcher.start();
      addTearDown(watcher.stop);

      service.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(watcher.statuses, [AuthStatus.signedIn]);
    });

    test("is told nothing before it starts following the user", () async {
      await anApplication();
      final watcher = _Watcher();

      service.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(watcher.statuses, isEmpty);
    });
  });

  group("MixinAuthStatusCallback.disposeUpdate", () {
    test("stops following the status of the user", () async {
      await anApplication();
      final watcher = _Watcher();
      await watcher.start();

      await watcher.stop();
      service.updateStatus(AuthStatus.signedIn);
      await pumpEventQueue();

      expect(watcher.statuses, isEmpty);
    });
  });
}
