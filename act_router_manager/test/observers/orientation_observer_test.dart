// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_router_manager/act_router_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_routes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<List<String>> askedOrientations;

  setUp(() {
    FakeGlobalManager.install();
    askedOrientations = [];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == "SystemChrome.setPreferredOrientations") {
          askedOrientations.add((call.arguments as List<Object?>).cast<String>());
        }

        return null;
      },
    );
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  /// Builds the manager of an application and displays its first page.
  Future<FakeRouterManager> pumpManager(WidgetTester tester) async {
    final manager = FakeRouterManager();
    await manager.initLifeCycle();
    await manager.initAfterManagersAndBeforeViews();
    addTearDown(manager.router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: manager.router));
    await tester.pumpAndSettle();

    return manager;
  }

  group("OrientationObserver", () {
    testWidgets("asks for the orientation of the page which is pushed", (tester) async {
      final manager = await pumpManager(tester);
      askedOrientations.clear();

      unawaited(manager.push(FakeRoute.scanner));
      await tester.pumpAndSettle();

      expect(askedOrientations.last, ScreenOrientationOption.landscapeOnly.orientations.names);
    });

    testWidgets("asks for the default orientation of a page which asks for none", (tester) async {
      final manager = await pumpManager(tester);
      askedOrientations.clear();

      unawaited(manager.push(FakeRoute.settings));
      await tester.pumpAndSettle();

      expect(askedOrientations.last, ScreenOrientationOption.mayRotate.orientations.names);
    });

    testWidgets("asks for the orientation of the page it goes back to", (tester) async {
      final manager = await pumpManager(tester);
      unawaited(manager.push(FakeRoute.scanner));
      await tester.pumpAndSettle();
      askedOrientations.clear();

      manager.pop();
      await tester.pumpAndSettle();

      expect(askedOrientations.last, ScreenOrientationOption.mayRotate.orientations.names);
    });

    testWidgets("asks for the orientation of the page which replaces another one", (tester) async {
      final manager = await pumpManager(tester);
      askedOrientations.clear();

      unawaited(manager.replace(FakeRoute.scanner));
      await tester.pumpAndSettle();

      expect(askedOrientations.last, ScreenOrientationOption.landscapeOnly.orientations.names);
    });
  });
}

/// The names the platform channel carries the orientations under.
extension on List<DeviceOrientation> {
  /// The names of the orientations.
  List<String> get names => map((orientation) => orientation.toString()).toList();
}
