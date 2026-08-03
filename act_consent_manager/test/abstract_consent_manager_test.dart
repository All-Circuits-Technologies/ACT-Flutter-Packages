// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_consent_manager/act_consent_manager.dart';
import 'package:act_intl/act_intl.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes/fake_consent.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

  late FakeGlobalManager globalManager;
  late FakeExternalLogger logs;
  late FakeLocalesApp locales;

  setUp(() async {
    globalManager = FakeGlobalManager.install();
    logs = FakeExternalLogger();
    locales = await FakeLocalesApp.install(globalManager);
  });

  tearDown(() async {
    FakeAssets.stop();
    await locales.dispose();
    await globalManager.reset();
  });

  /// The manager of an application which asks its users for [services].
  Future<FakeConsentManager> aManager(
    Map<FakeConsentType, AbstractConsentService> services,
  ) async {
    final manager = FakeConsentManager(services: services);
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  /// The service of a consent of the application under test.
  FakeConsentService aService() =>
      FakeConsentService(logsHelper: logs.buildHelper(category: "consent"));

  group("AbstractConsentBuilder", () {
    test("depends on the logger and on the locales of the application", () {
      final builder = FakeConsentBuilder(() => FakeConsentManager(services: const {}));

      expect(builder.dependsOn(), [LoggerManager, LocalesManager]);
    });
  });

  group("AbstractConsentManager.initLifeCycle", () {
    test("initializes every service of the application", () async {
      final service = aService();

      await aManager({FakeConsentType.terms: service});

      expect(service.consentState, ConsentStateEnum.unknown);
    });

    test("hands over the service of a consent", () async {
      final service = aService();
      final manager = await aManager({FakeConsentType.terms: service});

      expect(manager.getService<FakeOptions>(FakeConsentType.terms), service);
    });

    test("hands over nothing for a consent the application does not ask for", () async {
      final manager = await aManager({FakeConsentType.terms: aService()});

      expect(manager.getService<FakeOptions>(FakeConsentType.analytics), isNull);
    });
  });

  group("AbstractConsentManager.initAfterView", () {
    testWidgets("has every service load what it needs once the view is up", (tester) async {
      final service = aService();
      final manager = await aManager({FakeConsentType.terms: service});

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              unawaited(manager.initAfterView(context));

              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(service.latestVersionCalls, 1);
      expect(service.userDataCalls, 1);
    });
  });

  group("AbstractConsentManager", () {
    test("has every service read its text again when the locale changes", () async {
      final service = aService();
      await aManager({FakeConsentType.terms: service});
      await service.loadAllConsentInfo();

      locales.shownIn = const Locale("en", "GB");
      await pumpEventQueue();

      expect(service.latestVersionCalls, 2);
    });
  });

  group("AbstractConsentManager.disposeLifeCycle", () {
    test("closes the services and the observers of the application", () async {
      final controller = StreamController<bool>.broadcast();
      addTearDown(controller.close);
      final observer = FakeObserver(stream: controller.stream, get: () => true);
      final service = aService();
      final manager = await aManager({FakeConsentType.terms: service})
        ..register(observer);

      await manager.disposeLifeCycle();

      expect(service.stateStream, emitsDone);
    });
  });
}
