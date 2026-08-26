// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_internet_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;

  setUp(() => globalManager = FakeGlobalManager.install());

  tearDown(() async {
    FakeAssets.stop();
    await globalManager.reset();
  });

  /// Builds the manager of an application which tests [host], and initializes it.
  Future<InternetConnectivityManager> aManager({String host = reachableHost}) async {
    final config = await FakeInternetConfig.build(host: host);
    addTearDown(config.disposeLifeCycle);
    globalManager.managers.registerSingleton<FakeInternetConfig>(config);

    final manager = InternetConnectivityManager(configGetter: () => config);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("InternetConnectivityBuilder", () {
    test("depends on the logger manager and on the configuration", () {
      expect(InternetConnectivityBuilder<FakeInternetConfig>().dependsOn(), [
        LoggerManager,
        FakeInternetConfig,
      ]);
    });
  });

  group("InternetConnectivityManager", () {
    test("assumes there is a connection before it has tested one", () {
      final manager = InternetConnectivityManager(configGetter: FakeInternetConfig.new);

      expect(manager.hasConnection, isTrue);
    });

    test("says there is a connection when the server answers", () async {
      final manager = await aManager();

      expect(manager.hasConnection, isTrue);
    });

    test("says there is none when the server does not answer", () async {
      final manager = await aManager(host: unreachableHost);

      expect(manager.hasConnection, isFalse);
    });

    test("pushes the loss of the connection on its stream", () async {
      final config = await FakeInternetConfig.build(host: unreachableHost);
      addTearDown(config.disposeLifeCycle);
      final manager = InternetConnectivityManager(configGetter: () => config);
      addTearDown(manager.disposeLifeCycle);
      final lost = expectLater(manager.hasInternetStream, emits(isFalse));

      await manager.initLifeCycle();

      await lost;
    });

    test("pushes nothing when the connection is the one it already knew about", () async {
      final config = await FakeInternetConfig.build();
      addTearDown(config.disposeLifeCycle);
      final manager = InternetConnectivityManager(configGetter: () => config);
      addTearDown(manager.disposeLifeCycle);
      final pushed = <bool>[];
      manager.hasInternetStream.listen(pushed.add);

      await manager.initLifeCycle();
      await pumpEventQueue();

      expect(pushed, isEmpty);
    });
  });

  group("InternetConnectivityManager.disposeLifeCycle", () {
    test("closes the stream the application listens to", () async {
      final config = await FakeInternetConfig.build();
      addTearDown(config.disposeLifeCycle);
      final manager = InternetConnectivityManager(configGetter: () => config);
      await manager.initLifeCycle();
      final done = expectLater(manager.hasInternetStream, emitsDone);

      await manager.disposeLifeCycle();

      await done;
    });
  });
}
