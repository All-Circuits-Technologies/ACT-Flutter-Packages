// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The states an application goes through when it leaves the foreground.
const _toBackground = [
  AppLifecycleState.inactive,
  AppLifecycleState.hidden,
  AppLifecycleState.paused,
];

/// The states an application goes through when it comes back to the foreground.
const _toForeground = [
  AppLifecycleState.hidden,
  AppLifecycleState.inactive,
  AppLifecycleState.resumed,
];

/// Drives the binding through [states], as the platform would.
void _goThrough(List<AppLifecycleState> states) {
  for (final state in states) {
    WidgetsBinding.instance.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLifeCycleManager manager;

  setUp(() async {
    manager = AppLifeCycleManager();
    await manager.initLifeCycle();
  });

  tearDown(() => manager.disposeLifeCycle());

  group("AppLifeCycleManager", () {
    test("is a manager with a life cycle", () {
      expect(manager, isA<AbsWithLifeCycle>());
    });

    test("has no state before the application reports one", () {
      expect(manager.lifeCycleState, isNull);
    });
  });

  group("AppLifeCycleManager.lifeCycleState", () {
    test("follows the state of the application", () {
      _goThrough(_toBackground);

      expect(manager.lifeCycleState, AppLifecycleState.paused);

      _goThrough(_toForeground);

      expect(manager.lifeCycleState, AppLifecycleState.resumed);
    });
  });

  group("AppLifeCycleManager.lifeCycleStream", () {
    test("emits every state the application goes through", () async {
      final emitted = <AppLifecycleState?>[];
      final subscription = manager.lifeCycleStream.listen(emitted.add);

      _goThrough(_toBackground);
      await pumpEventQueue();

      expect(emitted, _toBackground);

      await subscription.cancel();
    });

    test("does not emit a state which does not change", () async {
      final emitted = <AppLifecycleState?>[];
      final subscription = manager.lifeCycleStream.listen(emitted.add);

      _goThrough(const [AppLifecycleState.inactive, AppLifecycleState.inactive]);
      await pumpEventQueue();

      expect(emitted, [AppLifecycleState.inactive]);

      await subscription.cancel();
    });

    test("serves several listeners at once", () async {
      final emitted = <AppLifecycleState?>[];
      final otherEmitted = <AppLifecycleState?>[];
      final subscription = manager.lifeCycleStream.listen(emitted.add);
      final otherSubscription = manager.lifeCycleStream.listen(otherEmitted.add);

      _goThrough(const [AppLifecycleState.inactive]);
      await pumpEventQueue();

      expect(emitted, [AppLifecycleState.inactive]);
      expect(otherEmitted, [AppLifecycleState.inactive]);

      await subscription.cancel();
      await otherSubscription.cancel();
    });
  });

  group("AppLifeCycleManager.waitForegroundApp", () {
    test("returns once the application has left and come back", () async {
      var returned = false;

      final future = manager
          .waitForegroundApp(
            leaveTheApp: () async {
              _goThrough(_toBackground);
              return true;
            },
          )
          .then((_) => returned = true);

      await pumpEventQueue();

      expect(returned, isFalse);

      _goThrough(_toForeground);
      await future;

      expect(returned, isTrue);
    });

    test("returns without waiting when the application is already in the foreground", () async {
      _goThrough(const [AppLifecycleState.resumed]);
      await pumpEventQueue();

      await expectLater(manager.waitForegroundApp(leaveTheApp: () async => false), completes);
    });
  });

  group("AppLifeCycleManager.disposeLifeCycle", () {
    test("closes the stream", () async {
      final done = expectLater(manager.lifeCycleStream, emitsDone);

      await manager.disposeLifeCycle();

      await done;
    });

    test("stops following the application", () async {
      await manager.disposeLifeCycle();

      _goThrough(const [AppLifecycleState.inactive]);
      await pumpEventQueue();

      expect(manager.lifeCycleState, isNull);
    });

    test("can be called twice", () async {
      await manager.disposeLifeCycle();

      await expectLater(manager.disposeLifeCycle(), completes);
    });
  });

  group("AppLifeCycleBuilder", () {
    test("depends on no other manager", () {
      expect(AppLifeCycleBuilder().dependsOn(), isEmpty);
    });

    test("builds an application life cycle manager", () {
      expect(AppLifeCycleBuilder().factory(), isA<AppLifeCycleManager>());
    });
  });
}
