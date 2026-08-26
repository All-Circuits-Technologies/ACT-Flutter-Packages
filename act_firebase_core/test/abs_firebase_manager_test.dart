// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_firebase_core/act_firebase_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_firebase_service.dart';

/// The options of the project of the application under test.
const _options = FirebaseOptions(
  apiKey: "aKey",
  appId: "anApp",
  messagingSenderId: "aSender",
  projectId: "aProject",
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(setupFirebaseCoreMocks);

  setUp(FakeGlobalManager.install);

  /// Builds the manager of an application which uses [services], and initializes it.
  ///
  /// Every application of a test is named apart, because Firebase keeps the applications it has
  /// already started and refuses to start one twice under the same name.
  Future<FakeFirebaseManager> aManager(
    String appName, {
    List<AbsFirebaseService> services = const [],
    bool loggerEnabled = true,
  }) async {
    final manager = FakeFirebaseManager(
      FirebaseManagerConfig(
        loggerEnabled: loggerEnabled,
        firebaseAppName: appName,
        options: _options,
        firebaseServices: services,
      ),
    );
    await manager.initLifeCycle();

    return manager;
  }

  group("AbsFirebaseBuilder", () {
    test("depends on the logger manager and on the configuration", () {
      final builder = FakeFirebaseBuilder(
        () => FakeFirebaseManager(const FirebaseManagerConfig(loggerEnabled: false)),
      );

      expect(builder.dependsOn(), [LoggerManager, AbstractConfigManager]);
    });
  });

  group("AbsFirebaseManager.initLifeCycle", () {
    test("initializes every service of the application", () async {
      final first = FakeFirebaseService();
      final second = FakeFirebaseService();

      await aManager("everyService", services: [first, second]);

      expect(first.initCount, 1);
      expect(second.initCount, 1);
    });

    test("hands each service the logs of the manager to hang under", () async {
      final service = FakeFirebaseService();

      await aManager("logsOfTheManager", services: [service]);

      expect(service.logsHelper?.categories, ["firebase", "aService"]);
    });

    test("starts an application which uses no service", () async {
      await expectLater(aManager("noService"), completes);
    });
  });

  group("AbsFirebaseManager.disposeLifeCycle", () {
    test("disposes every service of the application", () async {
      final first = FakeFirebaseService();
      final second = FakeFirebaseService();
      final manager = await aManager("disposedServices", services: [first, second]);

      await manager.disposeLifeCycle();

      expect(first.disposeCount, 1);
      expect(second.disposeCount, 1);
    });
  });
}
