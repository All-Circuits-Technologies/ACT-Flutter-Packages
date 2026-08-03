// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_foundation/act_foundation.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_contextual_views.dart';

/// The reason a view of the tests is displayed for.
const _aContext = FakeViewContext(uniqueKey: "terms");

void main() {
  late FakeExternalLogger logs;
  late FakeRouterManager router;

  setUp(() {
    FakeGlobalManager.install();
    logs = FakeExternalLogger();
    router = FakeRouterManager();
  });

  /// The view builder of an application which registers what [register] says.
  Future<FakeViewBuilder> aBuilder([void Function(FakeViewBuilder builder)? register]) async {
    final builder = FakeViewBuilder(register: register);
    await builder.initBuilder(
      routerManager: router,
      logsHelper: logs.buildHelper(category: "contextView"),
    );

    return builder;
  }

  group("AbstractViewBuilder.registerViewDisplay", () {
    test("displays the view which was registered for a reason", () async {
      AbstractViewContext? displayed;
      final builder = await aBuilder(
        (builder) => builder.registerViewDisplay<FakeViewContext>(
          context: _aContext,
          callback: (context, doAction) async {
            displayed = context;

            return const ViewDisplayResult<void>(status: ViewDisplayStatus.ok);
          },
        ),
      );

      final result = await builder.display<void>(context: _aContext);

      expect(result.status, ViewDisplayStatus.ok);
      expect(displayed, _aContext);
    });

    test("hands the view the reason it is displayed for, as the application wrote it", () async {
      const context = FakeCompulsoryContext(uniqueKey: "terms");
      var isCompulsory = false;
      final builder = await aBuilder(
        (builder) => builder.registerViewDisplay<FakeCompulsoryContext>(
          context: context,
          callback: (context, doAction) async {
            isCompulsory = context.isAcceptanceCompulsory;

            return const ViewDisplayResult<void>(status: ViewDisplayStatus.ok);
          },
        ),
      );

      await builder.display<void>(context: context);

      expect(isCompulsory, isTrue);
    });

    test("refuses to register a reason it already knows", () async {
      final builder = await aBuilder();
      builder.registerAbsViewDisplay(
        context: _aContext,
        callback: (context, doAction) async =>
            const ViewDisplayResult<void>(status: ViewDisplayStatus.ok),
      );

      expect(
        () => builder.registerAbsViewDisplay(
          context: _aContext,
          callback: (context, doAction) async => const ViewDisplayResult<void>.error(),
        ),
        throwsAssertionError,
      );
    });
  });

  group("AbstractViewBuilder.display", () {
    test("answers an error for a reason no view was registered for", () async {
      final builder = await aBuilder();

      final result = await builder.display<void>(context: _aContext);

      expect(result.status, ViewDisplayStatus.error);
      expect(logs.recordsAtLevel(LogsLevel.error), isNotEmpty);
    });

    test("gives back what the view answered, of the type the caller asked for", () async {
      final builder = await aBuilder(
        (builder) => builder.registerAbsViewDisplay(
          context: _aContext,
          callback: (context, doAction) async =>
              const ViewDisplayResult<String>(status: ViewDisplayStatus.yes, customResult: "a name"),
        ),
      );

      final result = await builder.display<String>(context: _aContext);

      expect(result.status, ViewDisplayStatus.yes);
      expect(result.customResult, "a name");
    });

    test("hands the action of the caller to the view", () async {
      final builder = await aBuilder(
        (builder) => builder.registerAbsViewDisplay(
          context: _aContext,
          callback: (context, doAction) async {
            await doAction!();

            return const ViewDisplayResult<void>(status: ViewDisplayStatus.ok);
          },
        ),
      );
      var called = false;

      await builder.display<void>(
        context: _aContext,
        doAction: () {
          called = true;

          return (true, null);
        },
      );

      expect(called, isTrue);
    });
  });

  group("AbstractViewBuilder.onContextualPage", () {
    test("pushes the page of the view, with what it needs to answer", () async {
      final builder = await aBuilder(
        (builder) => builder.onContextualPage(context: _aContext, route: FakeRoute.terms),
      );

      final display = builder.display<void>(context: _aContext);
      await pumpEventQueue();

      expect(router.pushed.single.route, FakeRoute.terms);
      final extra = router.extraOf<FakeViewContext>();
      expect(extra.context, _aContext);
      expect(extra.requestExtraAction, isNull);

      await extra.callWhenEnded(ViewDisplayStatus.yes);
      expect((await display).status, ViewDisplayStatus.yes);
    });

    test("pops the page of the view once it answered", () async {
      final builder = await aBuilder(
        (builder) => builder.onContextualPage(context: _aContext, route: FakeRoute.terms),
      );

      final display = builder.display<void>(context: _aContext);
      await pumpEventQueue();
      await router.extraOf<FakeViewContext>().callWhenEnded(ViewDisplayStatus.ok);
      await display;

      expect(router.popCount, 1);
    });

    test("leaves the page alone when the view already went away", () async {
      final builder = await aBuilder(
        (builder) => builder.onContextualPage(context: _aContext, route: FakeRoute.terms),
      );

      final display = builder.display<void>(context: _aContext);
      await pumpEventQueue();
      router.topView = FakeRoute.home;
      await router.extraOf<FakeViewContext>().callWhenEnded(ViewDisplayStatus.ok);
      await display;

      expect(router.popCount, 0);
    });

    test("hands the page the action of the caller, and keeps what it answered", () async {
      final builder = await aBuilder(
        (builder) => builder.onContextualPage(context: _aContext, route: FakeRoute.terms),
      );

      final display = builder.display<String>(
        context: _aContext,
        doAction: () async => (true, "a name"),
      );
      await pumpEventQueue();
      final extra = router.extraOf<FakeViewContext>();

      expect(await extra.requestExtraAction!(), isTrue);
      await extra.callWhenEnded(ViewDisplayStatus.ok);

      final result = await display;
      expect(result.customResult, "a name");
    });
  });

  group("AbstractViewBuilder.onContextualDialog", () {
    test("displays the dialog of the view, with what it needs to answer", () async {
      ExtraContextualViewConfig<FakeViewContext>? given;
      final builder = await aBuilder(
        (builder) => builder.onContextualDialog<FakeViewContext>(
          context: _aContext,
          displayDialog: (extra) async => given = extra,
        ),
      );

      final display = builder.display<void>(context: _aContext);
      await pumpEventQueue();

      expect(given?.context, _aContext);
      await given!.callWhenEnded(ViewDisplayStatus.no);

      expect((await display).status, ViewDisplayStatus.no);
      expect(router.pushed, isEmpty);
    });

    test("hands the dialog the action of the caller, and keeps what it answered", () async {
      ExtraContextualViewConfig<FakeViewContext>? given;
      final builder = await aBuilder(
        (builder) => builder.onContextualDialog<FakeViewContext>(
          context: _aContext,
          displayDialog: (extra) async => given = extra,
        ),
      );

      final display = builder.display<String>(
        context: _aContext,
        doAction: () async => (false, "a name"),
      );
      await pumpEventQueue();

      expect(await given!.requestExtraAction!(), isFalse);
      await given!.callWhenEnded(ViewDisplayStatus.custom);

      final result = await display;
      expect(result.status, ViewDisplayStatus.custom);
      expect(result.customResult, "a name");
    });
  });
}
