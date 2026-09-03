// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A manager which only takes the default UI life cycle of the mixin.
class _PlainManager extends AbsWithLifeCycle with MixinUiLifeCycle {}

/// A manager which records the order of the steps of its whole life cycle.
class _RecordingManager extends AbsWithLifeCycle with MixinUiLifeCycle {
  final List<String> steps = [];

  BuildContext? seenContext;

  Object? seenError;

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    steps.add("init");
  }

  @override
  Future<void> initAfterManagersAndBeforeViews() async {
    await super.initAfterManagersAndBeforeViews();
    steps.add("initAfterManagersAndBeforeViews");
  }

  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);
    steps.add("initAfterView");
    seenContext = context;
  }

  @override
  Future<void> onFatalErrorPageWillShow(Object error) async {
    await super.onFatalErrorPageWillShow(error);
    steps.add("onFatalErrorPageWillShow");
    seenError = error;
  }

  @override
  Future<void> disposeLifeCycle() async {
    steps.add("dispose");
    await super.disposeLifeCycle();
  }
}

/// Builds a widget which gives its context to [onContext].
Widget _contextProvider(void Function(BuildContext context) onContext) => Builder(
  builder: (context) {
    onContext(context);
    return const SizedBox.shrink();
  },
);

void main() {
  group("MixinUiLifeCycle.initAfterManagersAndBeforeViews", () {
    test("completes without doing anything when it is not overridden", () async {
      final manager = _PlainManager();

      await expectLater(manager.initAfterManagersAndBeforeViews(), completes);
    });

    test("runs the step of the derived class", () async {
      final manager = _RecordingManager();

      await manager.initAfterManagersAndBeforeViews();

      expect(manager.steps, ["initAfterManagersAndBeforeViews"]);
    });
  });

  group("MixinUiLifeCycle.initAfterView", () {
    testWidgets("completes without doing anything when it is not overridden", (tester) async {
      final manager = _PlainManager();
      late BuildContext viewContext;

      await tester.pumpWidget(_contextProvider((context) => viewContext = context));

      await expectLater(manager.initAfterView(viewContext), completes);
    });

    testWidgets("gives the context of the view to the derived class", (tester) async {
      final manager = _RecordingManager();
      late BuildContext viewContext;

      await tester.pumpWidget(_contextProvider((context) => viewContext = context));
      await manager.initAfterView(viewContext);

      expect(manager.seenContext, viewContext);
    });
  });

  group("MixinUiLifeCycle.onFatalErrorPageWillShow", () {
    test("completes without doing anything when it is not overridden", () async {
      final manager = _PlainManager();

      await expectLater(manager.onFatalErrorPageWillShow(StateError("a failure")), completes);
    });

    test("gives the error to the derived class", () async {
      final manager = _RecordingManager();
      final error = StateError("a failure");

      await manager.onFatalErrorPageWillShow(error);

      expect(manager.seenError, same(error));
      expect(manager.steps, ["onFatalErrorPageWillShow"]);
    });
  });

  group("MixinUiLifeCycle", () {
    testWidgets("runs the four steps of the life cycle in order", (tester) async {
      final manager = _RecordingManager();
      late BuildContext viewContext;

      await tester.pumpWidget(_contextProvider((context) => viewContext = context));
      await manager.initLifeCycle();
      await manager.initAfterManagersAndBeforeViews();
      await manager.initAfterView(viewContext);
      await manager.disposeLifeCycle();

      expect(manager.steps, [
        "init",
        "initAfterManagersAndBeforeViews",
        "initAfterView",
        "dispose",
      ]);
    });

    test("only applies to the managers which have a life cycle", () {
      expect(_PlainManager(), isA<AbsWithLifeCycle>());
    });
  });
}
