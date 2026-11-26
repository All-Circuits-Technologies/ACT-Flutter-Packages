// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The event a test sends to store a value in the bloc.
class FakeValueEvent extends BlocEventForMixin {
  /// The value the bloc keeps once the event is handled.
  final int value;

  /// Class constructor
  const FakeValueEvent(this.value);

  @override
  List<Object?> get props => [...super.props, value];
}

/// The state of the blocs a test drives.
class FakeBlocState extends BlocStateForMixin<FakeBlocState> {
  /// The states which were disposed, shared by every copy of the state.
  ///
  /// A state is immutable and is copied on every change, so the state a test holds is not the one
  /// the bloc disposes. The list is what the test reads to know what happened.
  final List<FakeBlocState> disposedStates;

  /// The value the bloc keeps.
  final int value;

  /// Class constructor
  FakeBlocState({List<FakeBlocState>? disposedStates, this.value = 0})
    : disposedStates = disposedStates ?? [];

  /// {@macro act_flutter_utility.BlocStateForMixin.copyWith}
  @override
  FakeBlocState copyWith({int? value}) =>
      FakeBlocState(disposedStates: disposedStates, value: value ?? this.value);

  @override
  Future<void> disposeLifeCycle() async {
    disposedStates.add(this);

    return super.disposeLifeCycle();
  }

  @override
  List<Object?> get props => [...super.props, value];
}

/// A bloc which keeps the value of the last event it received.
class FakeBloc extends BlocForMixin<FakeBlocState> {
  /// The number of times the bloc disposed its own life cycle.
  int disposeCount = 0;

  /// Class constructor
  FakeBloc(super.initialState);

  /// {@macro act_flutter_utility.BlocForMixin.registerMixinEvents}
  @override
  void registerMixinEvents() {
    super.registerMixinEvents();

    on<FakeValueEvent>((event, emit) => emit(state.copyWith(value: event.value)));
  }

  @override
  Future<void> disposeLifeCycle() async {
    disposeCount++;

    return super.disposeLifeCycle();
  }
}

/// A bloc which initializes itself asynchronously as soon as it is built.
class FakeAsyncInitBloc extends BlocForMixin<FakeBlocState> with MixinAsyncInitBloc<FakeBlocState> {
  /// The number of times the asynchronous initialization ran.
  int initCount = 0;

  /// Class constructor
  FakeAsyncInitBloc(super.initialState);

  /// {@macro act_flutter_utility.MixinAsyncInitBloc.initAsyncBloc}
  @override
  Future<void> initAsyncBloc({required Emitter<FakeBlocState> emit}) async {
    await super.initAsyncBloc(emit: emit);

    initCount++;
    emit(state.copyWith(value: initCount));
  }
}

/// A state which tells whether the page it describes is loading.
class FakeLoadingState extends BlocStateForMixin<FakeLoadingState>
    with MixinGenericLoadingState<FakeLoadingState> {
  /// {@macro act_flutter_utility.MixinGenericLoadingState.loading}
  @override
  final bool loading;

  /// {@macro act_flutter_utility.MixinGenericLoadingState.anErrorOccurred}
  @override
  final bool anErrorOccurred;

  /// Class constructor
  const FakeLoadingState({this.loading = false, this.anErrorOccurred = false});

  /// {@macro act_flutter_utility.BlocStateForMixin.copyWith}
  @override
  FakeLoadingState copyWith({bool? loading, bool? anErrorOccurred}) => FakeLoadingState(
    loading: loading ?? this.loading,
    anErrorOccurred: anErrorOccurred ?? this.anErrorOccurred,
  );

  @override
  List<Object?> get props => [...super.props, loading, anErrorOccurred];
}

/// A state which disables the interactions of its page for a reason of its own.
class FakeReadOnlyState extends BlocStateForMixin<FakeReadOnlyState>
    with MixinGenericLoadingState<FakeReadOnlyState> {
  /// True when the page shows values the user is not allowed to change.
  final bool readOnly;

  /// {@macro act_flutter_utility.MixinGenericLoadingState.loading}
  @override
  final bool loading;

  /// {@macro act_flutter_utility.MixinGenericLoadingState.interactionsDisabled}
  @override
  bool get interactionsDisabled => super.interactionsDisabled || readOnly;

  /// Class constructor
  const FakeReadOnlyState({this.readOnly = false, this.loading = false});

  /// {@macro act_flutter_utility.BlocStateForMixin.copyWith}
  @override
  FakeReadOnlyState copyWith({bool? readOnly, bool? loading}) =>
      FakeReadOnlyState(readOnly: readOnly ?? this.readOnly, loading: loading ?? this.loading);

  @override
  List<Object?> get props => [...super.props, readOnly, loading];
}
