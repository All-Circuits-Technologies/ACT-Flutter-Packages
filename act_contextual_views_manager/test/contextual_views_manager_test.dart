// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_contextual_views.dart';

/// The reason a view of the tests is displayed for.
const _aContext = FakeViewContext(uniqueKey: "terms");

void main() {
  late FakeGlobalManager globalManager;
  late FakeRouterManager router;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    router = FakeRouterManager();
    globalManager.managers.registerSingleton<FakeRouterManager>(router);
  });

  tearDown(() => globalManager.reset());

  /// The contextual views manager of an application which displays [builder].
  Future<ContextualViewsManager> aManager(FakeViewBuilder builder) async {
    final manager = ContextualViewsBuilder<FakeRouterManager>(viewBuilder: builder).factory();
    await manager.initLifeCycle();
    addTearDown(manager.disposeLifeCycle);

    return manager;
  }

  group("ContextualViewsBuilder", () {
    test("depends on the router and on the logger of the application", () {
      final builder = ContextualViewsBuilder<FakeRouterManager>(viewBuilder: FakeViewBuilder());

      expect(builder.dependsOn(), [FakeRouterManager, LoggerManager]);
    });
  });

  group("ContextualViewsManager.initLifeCycle", () {
    test("has the view builder of the application register its views", () async {
      var registered = false;

      await aManager(FakeViewBuilder(register: (builder) => registered = true));

      expect(registered, isTrue);
    });

    test("hands the router of the application to the view builder", () async {
      late FakeViewBuilder built;

      await aManager(FakeViewBuilder(register: (builder) => built = builder));

      expect(built.routerManagerOfTheApplication, router);
    });
  });

  group("ContextualViewsManager.display", () {
    test("has the view builder display the view of a reason", () async {
      final manager = await aManager(
        FakeViewBuilder(
          register: (builder) => builder.registerAbsViewDisplay(
            context: _aContext,
            callback: (context, doAction) async => const ViewDisplayResult<String>(
              status: ViewDisplayStatus.yes,
              customResult: "a name",
            ),
          ),
        ),
      );

      final result = await manager.display<String>(context: _aContext);

      expect(result.status, ViewDisplayStatus.yes);
      expect(result.customResult, "a name");
    });

    test("answers an error for a reason no view was registered for", () async {
      final manager = await aManager(FakeViewBuilder());

      expect((await manager.display<void>(context: _aContext)).status, ViewDisplayStatus.error);
    });
  });

  group("ContextualViewsManager.disposeLifeCycle", () {
    test("closes the view builder of the application", () async {
      final builder = FakeViewBuilder();
      final manager = await aManager(builder);

      await manager.disposeLifeCycle();

      expect(builder.disposeCount, 1);
    });
  });
}
