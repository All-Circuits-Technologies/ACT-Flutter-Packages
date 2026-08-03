// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_contextual_views.dart';

/// The reason the view of the tests is displayed for.
const _aContext = FakeViewContext(uniqueKey: "terms");

void main() {
  late FakeGlobalManager globalManager;
  late StreamController<bool> isOk;
  late List<ViewDisplayStatus> ended;

  setUp(() {
    globalManager = FakeGlobalManager.install();
    isOk = StreamController<bool>.broadcast();
    ended = [];
  });

  tearDown(() async {
    await isOk.close();
    await globalManager.reset();
  });

  /// The bloc of the page which requests the user.
  ///
  /// The page is shown while [isOkAtStart] says that what is asked of the user is not done yet, and
  /// it asks the user itself when [withAction] says that there is something to ask.
  Future<RequestContextualActionBloc<FakeViewContext>> aBloc({
    bool isOkAtStart = false,
    bool withAction = true,
    bool actionAnswer = true,
  }) async {
    final bloc = RequestContextualActionBloc<FakeViewContext>(
      config: ExtraContextualViewConfig<FakeViewContext>(
        context: _aContext,
        callWhenEnded: (status) async => ended.add(status),
        requestExtraAction: withAction ? () async => actionAnswer : null,
      ),
      isOkCallback: () => isOkAtStart,
      isOkStream: isOk.stream,
    );
    addTearDown(bloc.close);
    await pumpEventQueue();

    return bloc;
  }

  group("RequestContextualActionBloc", () {
    test("shows the page of a user who has something to answer", () async {
      final bloc = await aBloc();

      expect(bloc.state.isOk, isFalse);
      expect(bloc.state.loading, isFalse);
      expect(ended, isEmpty);
    });

    test("ends the view straight away for a user who has nothing to answer", () async {
      final bloc = await aBloc(isOkAtStart: true);

      expect(ended, [ViewDisplayStatus.ok]);
      expect(bloc.state.isOk, isTrue);
    });

    test("ends the view when what is asked of the user is answered elsewhere", () async {
      await aBloc(withAction: false);

      isOk.add(true);
      await pumpEventQueue();

      expect(ended, [ViewDisplayStatus.ok]);
    });

    test("waits for the user when there is something to ask, whatever else answers", () async {
      final bloc = await aBloc();

      isOk.add(true);
      await pumpEventQueue();

      expect(bloc.state.isOk, isTrue);
      expect(ended, isEmpty);
    });

    test("ends the view once the user answered what was asked", () async {
      final bloc = await aBloc();

      bloc.add(const RequestContextualActionAskEvent());
      await pumpEventQueue();

      expect(bloc.state.isOk, isTrue);
      expect(bloc.state.loading, isFalse);
      expect(ended, [ViewDisplayStatus.ok]);
    });

    test("keeps the page open when the user answered no to what was asked", () async {
      final bloc = await aBloc(actionAnswer: false);

      bloc.add(const RequestContextualActionAskEvent());
      await pumpEventQueue();

      expect(bloc.state.isOk, isFalse);
      expect(bloc.state.loading, isFalse);
      expect(ended, isEmpty);
    });

    test("ends the view with an error when the user refused to be asked", () async {
      final bloc = await aBloc();

      bloc.add(const RequestContextualActionRefusedEvent());
      await pumpEventQueue();

      expect(ended, [ViewDisplayStatus.error]);
    });

    test("ends the view once only, whatever happens next", () async {
      final bloc = await aBloc();

      bloc
        ..add(const RequestContextualActionAskEvent())
        ..add(const RequestContextualActionRefusedEvent());
      await pumpEventQueue();

      expect(ended, [ViewDisplayStatus.ok]);
    });

    test("stops following what is answered elsewhere once it is closed", () async {
      final bloc = await aBloc(withAction: false);

      await bloc.close();
      isOk.add(true);
      await pumpEventQueue();

      expect(ended, isEmpty);
    });
  });
}
