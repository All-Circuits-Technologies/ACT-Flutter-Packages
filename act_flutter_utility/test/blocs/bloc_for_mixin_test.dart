// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_blocs.dart';

void main() {
  group("BlocEventForMixin", () {
    test("holds two events carrying the same value for equal", () {
      expect(const FakeValueEvent(3), const FakeValueEvent(3));
    });

    test("tells two events carrying a different value apart", () {
      expect(const FakeValueEvent(3), isNot(const FakeValueEvent(4)));
    });
  });

  group("BlocStateForMixin.copyWith", () {
    test("keeps the values the caller did not give", () {
      final state = FakeBlocState(value: 7);

      expect(state.copyWith().value, 7);
    });

    test("replaces the value the caller gave", () {
      final state = FakeBlocState(value: 7);

      expect(state.copyWith(value: 8).value, 8);
    });
  });

  group("BlocForMixin", () {
    test("handles the events its mixins registered", () async {
      final bloc = FakeBloc(FakeBlocState());

      bloc.add(const FakeValueEvent(5));
      await pumpEventQueue();

      expect(bloc.state.value, 5);
    });

    test("disposes its own life cycle when it is closed", () async {
      final bloc = FakeBloc(FakeBlocState());

      await bloc.close();

      expect(bloc.disposeCount, 1);
    });

    test("disposes the life cycle of the state it holds when it is closed", () async {
      final initialState = FakeBlocState();
      final bloc = FakeBloc(initialState);
      bloc.add(const FakeValueEvent(5));
      await pumpEventQueue();

      await bloc.close();

      expect(initialState.disposedStates.single.value, 5);
    });
  });
}
