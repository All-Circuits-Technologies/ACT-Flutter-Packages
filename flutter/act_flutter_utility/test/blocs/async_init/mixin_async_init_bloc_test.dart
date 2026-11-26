// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_blocs.dart';

void main() {
  group("MixinAsyncInitBloc", () {
    test("initializes the bloc as soon as it is built", () async {
      final bloc = FakeAsyncInitBloc(FakeBlocState());
      addTearDown(bloc.close);

      await pumpEventQueue();

      expect(bloc.initCount, 1);
    });

    test("emits the state the initialization built", () async {
      final bloc = FakeAsyncInitBloc(FakeBlocState());
      addTearDown(bloc.close);

      await pumpEventQueue();

      expect(bloc.state.value, 1);
    });

    test("initializes the bloc again when the event is added again", () async {
      final bloc = FakeAsyncInitBloc(FakeBlocState());
      addTearDown(bloc.close);
      await pumpEventQueue();

      bloc.add(const AsyncInitEvent());
      await pumpEventQueue();

      expect(bloc.initCount, 2);
    });
  });
}
