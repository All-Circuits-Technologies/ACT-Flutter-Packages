// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_app_life_cycle_manager/act_app_life_cycle_manager.dart';
import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_enable_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGlobalManager globalManager;
  late FakeAppLifeCycleManager lifeCycle;
  late FakeServiceViewBuilder views;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    lifeCycle = FakeAppLifeCycleManager();
    views = FakeServiceViewBuilder();
    FakeAppSettings.serve();

    globalGetIt()
      ..registerSingleton<AppLifeCycleManager>(lifeCycle)
      ..registerSingleton<FakeServiceRouterManager>(FakeServiceRouterManager());

    final contextualViews = ContextualViewsBuilder<FakeServiceRouterManager>(
      viewBuilder: views,
    ).factory();
    await contextualViews.initLifeCycle();
    globalGetIt().registerSingleton<ContextualViewsManager>(contextualViews);
    addTearDown(contextualViews.disposeLifeCycle);
  });

  tearDown(() async {
    FakeAppSettings.stop();
    await lifeCycle.close();
    await globalManager.reset();
  });

  /// The service of an application which asks the user to enable a system service.
  FakeEnableService aService({bool enablingWorks = true}) {
    final service = FakeEnableService(enablingWorks: enablingWorks);
    addTearDown(service.disposeLifeCycle);

    return service;
  }

  group("MEnableService.isEnabled", () {
    test("says that a service nothing was said about is not enabled", () {
      expect(aService().isEnabled, isFalse);
    });

    test("says that a service which was enabled is enabled", () {
      final service = aService()..tellEnabled(isEnabled: true);

      expect(service.isEnabled, isTrue);
    });
  });

  group("MEnableService.enabledStream", () {
    test("tells the application when the service is enabled", () async {
      final service = aService();
      final enabled = <bool>[];
      service.enabledStream.listen(enabled.add);

      service.tellEnabled(isEnabled: true);
      await pumpEventQueue();

      expect(enabled, [true]);
    });

    test("says nothing when the state of the service did not change", () async {
      final service = aService()..tellEnabled(isEnabled: true);
      final enabled = <bool>[];
      service.enabledStream.listen(enabled.add);

      service.tellEnabled(isEnabled: true);
      await pumpEventQueue();

      expect(enabled, isEmpty);
    });

    test("tells the application when the service is disabled again", () async {
      final service = aService()..tellEnabled(isEnabled: true);
      final enabled = <bool>[];
      service.enabledStream.listen(enabled.add);

      service.tellEnabled(isEnabled: false);
      await pumpEventQueue();

      expect(enabled, [false]);
    });
  });

  group("MEnableService.checkAndAskForEnabling", () {
    test("asks the service to enable itself", () async {
      final service = aService();

      final enabled = await service.checkAndAskForEnabling();

      expect(enabled, isTrue);
      expect(service.askCount, 1);
    });

    test("answers what it already knows when it is told to ask nothing", () async {
      final service = aService()..tellEnabled(isEnabled: true);

      final enabled = await service.checkAndAskForEnabling(askToUser: false);

      expect(enabled, isTrue);
      expect(service.askCount, 0);
    });

    test("answers that a service it knows nothing of is not enabled", () async {
      final service = aService();

      expect(await service.checkAndAskForEnabling(askToUser: false), isFalse);
      expect(service.askCount, 0);
    });

    test("answers that the service was not enabled when the enabling failed", () async {
      final service = aService(enablingWorks: false);

      expect(await service.checkAndAskForEnabling(), isFalse);
    });
  });

  group("MEnableService.requestUser", () {
    test("displays the page of the service which has to be enabled", () async {
      final service = aService();

      final result = await service.ask();

      expect(result.status, ViewDisplayStatus.ok);
      expect(views.displayed.single.uniqueKey, "enable_service:$anElement");
    });

    test("has the page of the application enable the service", () async {
      final service = aService();

      await service.ask();

      expect(service.askCount, 1);
      expect(service.isEnabled, isTrue);
    });

    test("answers what the page of the application answered", () async {
      final service = aService();

      final result = await service.ask();

      expect(result.customResult, isTrue);
    });

    test("enables nothing when the user leaves the page", () async {
      views.userAgrees = false;
      final service = aService();

      final result = await service.ask();

      expect(result.status, ViewDisplayStatus.no);
      expect(service.askCount, 0);
    });

    test("displays the page it is given rather than the one of its own service", () async {
      final service = aService();

      await service.ask(
        overrideContext: EnableServiceViewContext(element: EnableServiceElement.wifi),
      );

      expect(views.displayed.single.uniqueKey, "enable_service:${EnableServiceElement.wifi}");
    });

    test("enables the service without a page when it is told to display none", () async {
      final service = aService();

      final result = await service.ask(displayContextualIfNeeded: false);

      expect(result.status, ViewDisplayStatus.ok);
      expect(result.customResult, isTrue);
      expect(views.displayed, isEmpty);
      expect(service.askCount, 1);
    });

    test("answers an error when the enabling fails without a page", () async {
      final service = aService(enablingWorks: false);

      final result = await service.ask(displayContextualIfNeeded: false);

      expect(result.status, ViewDisplayStatus.error);
    });

    test("answers that everything is fine when there is nothing to do at all", () async {
      final service = aService();

      final result = await service.ask(displayContextualIfNeeded: false, withEnabling: false);

      expect(result.status, ViewDisplayStatus.ok);
      expect(service.askCount, 0);
    });
  });

  group("MEnableService.openAppSettingAndWaitForUpdate", () {
    test("opens the settings of the device and waits for the application to come back", () async {
      final service = aService();

      await service.openSettings();

      expect(FakeAppSettings.opened, isNotEmpty);
      expect(lifeCycle.waitCount, 1);
    });

    test("answers that the service is enabled when the user enabled it", () async {
      final service = aService();
      lifeCycle.waitCount = 0;

      final enabled = await service.openSettings();

      expect(enabled, isFalse);

      service.tellEnabled(isEnabled: true);

      expect(await service.openSettings(), isTrue);
    });

    test("gives up once the timeout is over", () async {
      final service = aService();

      final enabled = await service.openSettings(timeout: const Duration(milliseconds: 50));

      expect(enabled, isFalse);
    });
  });

  group("MEnableService.disposeLifeCycle", () {
    test("stops telling the application about the service", () async {
      final service = FakeEnableService();
      var closed = false;
      service.enabledStream.listen(null, onDone: () => closed = true);

      await service.disposeLifeCycle();
      await pumpEventQueue();

      expect(closed, isTrue);
    });
  });
}
