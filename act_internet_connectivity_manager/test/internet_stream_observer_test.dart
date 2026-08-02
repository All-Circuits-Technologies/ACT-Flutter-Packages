// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_internet_connectivity_manager/act_internet_connectivity_manager.dart';
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

  /// Registers the manager of an application which tests [host], and initializes it.
  Future<InternetConnectivityManager> aManager({String host = reachableHost}) async {
    final config = await FakeInternetConfig.build(host: host);
    addTearDown(config.disposeLifeCycle);

    final manager = InternetConnectivityManager(configGetter: () => config);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);
    globalManager.managers.registerSingleton<InternetConnectivityManager>(manager);

    return manager;
  }

  group("InternetStreamObserver", () {
    test("reads the connection the manager already knows about", () async {
      await aManager();

      expect(InternetStreamObserver().isValid, isTrue);
    });

    test("reads the loss of the connection the manager already knows about", () async {
      await aManager(host: unreachableHost);

      expect(InternetStreamObserver().isValid, isFalse);
    });
  });
}
