// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:ui';

import 'package:act_foundation/act_foundation.dart';
import 'package:act_global_manager/src/types/global_manager_ui_state.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../fakes/fake_app_config_manager.dart';
import '../fakes/fake_global_managers.dart';
import '../fakes/fake_managers.dart';

/// A manager whose initialization fails.
class _FailingManager extends FakeManager {
  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    throw StateError("the initialization failed");
  }
}

/// A builder which hands the logger manager of the test to the global manager, so that the global
/// manager initializes it as it does the managers of an application.
class _LoggerManagerBuilder extends AbsLifeCycleFactory<LoggerManager> {
  /// Class constructor
  _LoggerManagerBuilder(LoggerManager loggerManager) : super(() => loggerManager);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [];
}

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: "an app",
      packageName: "com.allcircuits.app",
      version: "1.2.3",
      buildNumber: "4",
      buildSignature: "",
    ),
  );

  group("MixinUiGlobalManager.initLifeCycle", () {
    testWidgets("initializes the managers which depend on the UI before the first view", (
      tester,
    ) async {
      final uiManager = FakeUiManager();
      final manager = FakeUiGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeUiManagerBuilder(uiManager)),
      );

      await manager.initLifeCycle();

      expect(uiManager.initBeforeViewsCount, 1);
      expect(uiManager.initAfterViewContexts, isEmpty);
    });

    testWidgets("initializes the managers which depend on the UI only once", (tester) async {
      final uiManager = FakeUiManager();
      final manager = FakeUiGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeUiManagerBuilder(uiManager)),
      );
      await manager.initLifeCycle();

      await manager.initLifeCycle();

      expect(uiManager.initBeforeViewsCount, 1);
    });

    testWidgets("leaves the managers which don't depend on the UI alone", (tester) async {
      final plainManager = FakeManager();
      final manager = FakeUiGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeManagerBuilder(plainManager)),
      );

      await manager.initLifeCycle();

      expect(manager.uiManagersOfTheApp, isEmpty);
      expect(manager.managersOfTheApp, [plainManager]);
    });
  });

  group("MixinUiGlobalManager.initInFirstView", () {
    testWidgets("initializes the managers which depend on the UI with the context", (tester) async {
      final uiManager = FakeUiManager();
      final manager = FakeUiGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeUiManagerBuilder(uiManager)),
      );
      await manager.initLifeCycle();
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));

      final isFirstCall = manager.initInFirstView(context);
      await tester.pump();

      expect(isFirstCall, isTrue);
      expect(uiManager.initAfterViewContexts, [context]);
    });

    testWidgets("does nothing more when the first view has already been built", (tester) async {
      final uiManager = FakeUiManager();
      final manager = FakeUiGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeUiManagerBuilder(uiManager)),
      );
      await manager.initLifeCycle();
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      manager.initInFirstView(context);
      await tester.pump();

      final isFirstCall = manager.initInFirstView(context);
      await tester.pump();

      expect(isFirstCall, isFalse);
      expect(uiManager.initAfterViewContexts.length, 1);
    });

    testWidgets("advances to the state of the first widget", (tester) async {
      final manager = FakeUiGlobalManager();
      await manager.initLifeCycle();
      await tester.pumpWidget(const SizedBox());

      manager.initInFirstView(tester.element(find.byType(SizedBox)));
      await tester.pump();

      expect(manager.advanceTo(GlobalManagerUiState.initForWidget), isFalse);
    });
  });

  group("MixinUiGlobalManager.runActApp", () {
    testWidgets("runs the application once the managers are initialized", (tester) async {
      final uiManager = FakeUiManager();
      final manager = FakeUiGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeUiManagerBuilder(uiManager)),
      );

      await manager.runActApp(const Text("the app", textDirection: TextDirection.ltr));
      await tester.pump();

      expect(find.text("the app"), findsOneWidget);
      expect(uiManager.initCount, 1);
      expect(uiManager.initBeforeViewsCount, 1);
    });

    testWidgets("runs the page of the fatal error when the initialization fails", (tester) async {
      final manager = FakeUiGlobalManager(
        fatalErrorPage: const Text("the error page", textDirection: TextDirection.ltr),
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeManagerBuilder(_FailingManager())),
      );

      await manager.runActApp(const Text("the app", textDirection: TextDirection.ltr));
      await tester.pump();

      expect(find.text("the error page"), findsOneWidget);
      expect(find.text("the app"), findsNothing);
    });

    testWidgets("tells the UI managers before the fatal error page is shown", (tester) async {
      final uiManager = FakeUiManager();
      final manager = FakeUiGlobalManager(
        fatalErrorPage: const Text("the error page", textDirection: TextDirection.ltr),
        onRegisterManagers: (globalManager) async {
          globalManager.register(FakeUiManagerBuilder(uiManager));
          // The failing manager depends on the UI one so it initializes first: it is then
          // registered by the time the error is caught, which is what lets the notification reach
          // it.
          globalManager.register(
            FakeManagerBuilder(_FailingManager(), dependencies: [FakeUiManager]),
          );
        },
      );

      await manager.runActApp(const Text("the app", textDirection: TextDirection.ltr));
      await tester.pump();

      expect(uiManager.fatalErrorPageErrors, [isA<StateError>()]);
      expect(uiManager.initAfterViewContexts, isEmpty);
    });

    testWidgets("does not tell the UI managers about a fatal error when the app starts", (
      tester,
    ) async {
      final uiManager = FakeUiManager();
      final manager = FakeUiGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeUiManagerBuilder(uiManager)),
      );

      await manager.runActApp(const Text("the app", textDirection: TextDirection.ltr));
      await tester.pump();

      expect(uiManager.fatalErrorPageErrors, isEmpty);
    });

    testWidgets("gives up when the initialization fails and there is no page to display", (
      tester,
    ) async {
      final manager = FakeUiGlobalManager(
        onRegisterManagers: (globalManager) async =>
            globalManager.register(FakeManagerBuilder(_FailingManager())),
      );

      await expectLater(
        manager.runActApp(const Text("the app", textDirection: TextDirection.ltr)),
        throwsA(anything),
      );
    });
  });

  group("MixinUiGlobalManager error hooks", () {
    late FakeExternalLogger logs;
    late FlutterExceptionHandler? initialFlutterHandler;
    late ErrorCallback? initialPlatformHandler;

    setUp(() {
      logs = FakeExternalLogger();
      initialFlutterHandler = FlutterError.onError;
      initialPlatformHandler = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      FlutterError.onError = initialFlutterHandler;
      PlatformDispatcher.instance.onError = initialPlatformHandler;
    });

    /// Builds a global manager which logs to the fake logger of the test, and runs its application
    /// so that the hooks are installed.
    Future<FakeUiGlobalManager> startedManager() async {
      final manager = FakeUiGlobalManager(logger: logs.buildHelper());
      await manager.runActApp(const Text("the app", textDirection: TextDirection.ltr));

      return manager;
    }

    /// Reports an error of Flutter the way the framework does when nothing caught it.
    void aFlutterError() =>
        FlutterError.onError!(FlutterErrorDetails(exception: Exception("a failure")));

    /// Reports an error of the platform the way the framework does when nothing caught it.
    bool aPlatformError() =>
        PlatformDispatcher.instance.onError!(Exception("a failure"), StackTrace.empty);

    testWidgets("logs the errors of Flutter at the error level", (tester) async {
      await startedManager();

      aFlutterError();

      expect(logs.records.length, 1);
      expect(logs.records.first.level, LogsLevel.error);
      expect(logs.records.first.message, contains("a failure"));
    });

    testWidgets("gives the errors of Flutter to the handlers it is given", (tester) async {
      final manager = await startedManager();
      final handled = <FlutterErrorDetails>[];
      manager.addFlutterExceptionHandler(handled.add);

      aFlutterError();

      expect(handled.length, 1);
      expect(handled.first.exception, isA<Exception>());
    });

    testWidgets("stops giving the errors of Flutter to a handler which has been removed", (
      tester,
    ) async {
      final manager = await startedManager();
      final handled = <FlutterErrorDetails>[];
      manager
        ..addFlutterExceptionHandler(handled.add)
        ..removeFlutterExceptionHandler(handled.add);

      aFlutterError();

      expect(handled, isEmpty);
    });

    testWidgets("gives the errors of the platform to the logger manager once it is initialized", (
      tester,
    ) async {
      final config = await FakeAppConfigManager.withContent("logs:\n  level: trace");
      final loggerManager = DefaultLoggerManager(loggerConfigGetter: () => config);
      final manager = FakeUiGlobalManager(
        logger: logs.buildHelper(),
        onRegisterManagers: (globalManager) async =>
            globalManager.register<LoggerManager>(_LoggerManagerBuilder(loggerManager)),
      );
      // The logger manager works with real asynchronous operations, which the fake clock of the
      // widget tests doesn't run
      await tester.runAsync(
        () => manager.runActApp(const Text("the app", textDirection: TextDirection.ltr)),
      );
      final handled = <Object>[];
      loggerManager.addPlatformErrorCallback((exception, stackTrace) => handled.add(exception));

      final isHandled = aPlatformError();

      expect(isHandled, isTrue);
      expect(handled, [isA<Exception>()]);

      await tester.runAsync(loggerManager.disposeLifeCycle);
      await config.disposeLifeCycle();
      FakeAssets.stop();
    });

    testWidgets("logs the errors of the platform itself when no logger manager is ready", (
      tester,
    ) async {
      await startedManager();

      final isHandled = aPlatformError();

      expect(isHandled, isTrue);
      expect(logs.records.length, 1);
      expect(logs.records.first.level, LogsLevel.error);
      expect(logs.records.first.message, contains("a failure"));
    });

    testWidgets("installs the hooks when the application runs, and not before", (tester) async {
      final manager = FakeUiGlobalManager(logger: logs.buildHelper());
      final flutterHandlerBefore = FlutterError.onError;
      final platformHandlerBefore = PlatformDispatcher.instance.onError;

      await manager.runActApp(const Text("the app", textDirection: TextDirection.ltr));

      expect(FlutterError.onError, isNot(same(flutterHandlerBefore)));
      expect(PlatformDispatcher.instance.onError, isNot(same(platformHandlerBefore)));
    });
  });

  group("MixinUiGlobalManager.getGlobalManagerStates", () {
    testWidgets("goes through the states of an application with a view", (tester) async {
      expect(FakeUiGlobalManager().statesOfTheApp, GlobalManagerUiState.getAllColumns());
    });

    testWidgets("gives its states to the manager as soon as it is built", (tester) async {
      final manager = FakeUiGlobalManager();

      expect(manager.advanceTo(GlobalManagerUiState.initForWidget), isTrue);
    });
  });
}
