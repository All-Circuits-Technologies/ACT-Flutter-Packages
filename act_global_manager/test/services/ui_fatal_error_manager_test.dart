// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../fakes/fake_global_managers.dart';

/// A logger manager which counts how many error handlers were registered on it, and skips the real
/// initialization which needs a configuration.
class _CountingLoggerManager extends LoggerManager {
  /// Number of times a flutter exception handler was registered.
  int flutterHandlerCount = 0;

  /// Number of times a platform error callback was registered.
  int platformCallbackCount = 0;

  /// Class constructor
  _CountingLoggerManager() : super(loggerConfigGetter: _unusedConfigGetter);

  static Never _unusedConfigGetter() => throw UnimplementedError();

  /// {@macro act_life_cycle.MixinWithLifeCycle.initLifeCycle}
  @override
  // The real initialization needs a configuration; it is skipped so super is not called.
  // ignore: must_call_super
  Future<void> initLifeCycle() async {}

  @override
  void addFlutterExceptionHandler(FlutterExceptionHandler handler) => flutterHandlerCount++;

  @override
  void addPlatformErrorCallback(ActLogsErrorCallback callback) => platformCallbackCount++;
}

/// A builder of the [_CountingLoggerManager] registered under [LoggerManager].
class _CountingLoggerBuilder extends AbsLifeCycleFactory<LoggerManager> {
  /// Class constructor
  _CountingLoggerBuilder(LoggerManager logger) : super(() => logger);

  /// {@macro act_life_cycle.AbsLifeCycleFactory.dependsOn}
  @override
  Iterable<Type> dependsOn() => [];
}

void main() {
  tearDown(GetIt.instance.reset);

  UiFatalErrorManager buildManager() => UiFatalErrorManager(
    buildFatalErrorPage: (error) => Text("error: $error", textDirection: TextDirection.ltr),
  );

  Future<void> pumpWrappedApp(WidgetTester tester, UiFatalErrorManager manager) => tester.pumpWidget(
    manager.wrapWithFatalErrorWidget(
      child: const Text("the app", textDirection: TextDirection.ltr),
    ),
  );

  group("UiFatalErrorManager", () {
    testWidgets("shows the application while no fatal error occurred", (tester) async {
      final manager = buildManager();

      await pumpWrappedApp(tester, manager);

      expect(find.text("the app"), findsOneWidget);
    });

    testWidgets("shows the fatal error page once a fatal error is displayed", (tester) async {
      final manager = buildManager();
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("boom"));
      await tester.pump();

      expect(find.text("the app"), findsNothing);
      expect(find.textContaining("boom"), findsOneWidget);
    });

    testWidgets("keeps the first fatal error when several occur", (tester) async {
      final manager = buildManager();
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("first"));
      manager.displayFatalErrorPage(StateError("second"));
      await tester.pump();

      expect(find.textContaining("first"), findsOneWidget);
      expect(find.textContaining("second"), findsNothing);
    });

    testWidgets("notifies the will-show handlers with the error", (tester) async {
      final manager = buildManager();
      final seenErrors = <Object>[];
      manager.addFatalErrorWillShowHandler((error) async => seenErrors.add(error));
      await pumpWrappedApp(tester, manager);

      final error = StateError("boom");
      manager.displayFatalErrorPage(error);
      await tester.pump();

      expect(seenErrors, [same(error)]);
    });

    testWidgets("notifies the will-show handlers only once", (tester) async {
      final manager = buildManager();
      var calls = 0;
      manager.addFatalErrorWillShowHandler((error) async => calls++);
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("first"));
      manager.displayFatalErrorPage(StateError("second"));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets("stops notifying a removed will-show handler", (tester) async {
      final manager = buildManager();
      var calls = 0;
      Future<void> handler(Object error) async => calls++;
      manager.addFatalErrorWillShowHandler(handler);
      manager.removeFatalErrorWillShowHandler(handler);
      await pumpWrappedApp(tester, manager);

      manager.displayFatalErrorPage(StateError("boom"));
      await tester.pump();

      expect(calls, 0);
    });
  });

  group("UiFatalErrorManager.initLifeCycle", () {
    setUp(
      () => PackageInfo.setMockInitialValues(
        appName: "an app",
        packageName: "com.allcircuits.app",
        version: "1.2.3",
        buildNumber: "4",
        buildSignature: "",
      ),
    );

    testWidgets("hooks the logger error handlers when it is initialized", (tester) async {
      final logger = _CountingLoggerManager();
      final host = FakeGlobalManager(
        onRegisterManagers: (globalManager) async {
          globalManager.register<LoggerManager>(_CountingLoggerBuilder(logger));
          globalManager.register<UiFatalErrorManager>(
            UiFatalErrorBuilder((error) => const SizedBox()),
          );
        },
      );

      await host.initLifeCycle();

      expect(logger.flutterHandlerCount, 1);
      expect(logger.platformCallbackCount, 1);
    });
  });
}
