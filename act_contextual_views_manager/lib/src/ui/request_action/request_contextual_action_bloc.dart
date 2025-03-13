// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_flutter_utility/act_flutter_utility.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mutex/mutex.dart';

/// This bloc is used to request the user and waits for the associated status update
class RequestContextualActionBloc<ViewContext extends AbstractViewContext>
    extends BlocForMixin<RequestContextualActionState> {
  /// Subscription to the isOk stream
  late final StreamSubscription _isOkSub;

  /// The extra contextual config used when the view has been displayed
  final ExtraContextualViewConfig<ViewContext> config;

  /// Mutex of the process end
  final Mutex _whenEndedMutex;

  /// If true, that means the method to call when process is ended has already been called
  bool _whenEndedCalled;

  /// Class constructor
  ///
  /// [isOkCallback] is used to know the current state
  RequestContextualActionBloc({
    required this.config,
    required bool Function() isOkCallback,
    required Stream<bool> isOkStream,
  })  : _whenEndedCalled = false,
        _whenEndedMutex = Mutex(),
        super(RequestContextualActionState.init(
          isOk: isOkCallback(),
        )) {
    on<RequestContextualActionInitEvent>(_onInitCallback);
    on<RequestContextualActionNewStateEvent>(_onIsOkUpdated);
    on<RequestContextualActionAskEvent>(_onRequestUser);
    on<RequestContextualActionRefusedEvent>(_onUserRefused);

    _isOkSub = isOkStream.listen(_onIsOkStatus);

    add(const RequestContextualActionInitEvent());
  }

  /// Called at the bloc initialisation
  Future<void> _onInitCallback(
    RequestContextualActionInitEvent event,
    Emitter<RequestContextualActionState> emitter,
  ) async {
    if (state.isOk) {
      // Nothing more to do
      await _manageCallWhenEnded(ViewDisplayStatus.ok);
      return;
    }

    emitter.call(state.copyWithLoadingState(
      loading: false,
    ));
  }

  /// Called when the 'is ok' changes
  void _onIsOkStatus(bool isOk) {
    add(RequestContextualActionNewStateEvent(isOk: isOk));
  }

  /// Called to update the state with the new [event.isStatusOk] status
  Future<void> _onIsOkUpdated(
    RequestContextualActionNewStateEvent event,
    Emitter<RequestContextualActionState> emitter,
  ) async {
    emitter.call(state.copyWithResultState(
      isOk: event.isOk,
    ));

    if (config.requestExtraAction == null && state.isOk) {
      // Nothing more to do
      // In case the user needs to be requested, we don't manage the end until the method is called
      await _manageCallWhenEnded(ViewDisplayStatus.ok);
      return;
    }
  }

  /// Called when the user has refused to go further
  Future<void> _onUserRefused(
    RequestContextualActionRefusedEvent event,
    Emitter<RequestContextualActionState> emitter,
  ) async {
    emitter.call(state.copyWithLoadingState(
      loading: true,
    ));

    await _manageCallWhenEnded(ViewDisplayStatus.error);
  }

  /// Called to request the user
  Future<void> _onRequestUser(
    RequestContextualActionAskEvent event,
    Emitter<RequestContextualActionState> emitter,
  ) =>
      _whenEndedMutex.protect(() async {
        emitter.call(state.copyWithLoadingState(
          loading: true,
        ));

        var isOk = true;

        if (config.requestExtraAction != null) {
          isOk = await config.requestExtraAction!();
        }

        emitter.call(state.copyWithResultState(
          isOk: isOk,
          loading: false,
        ));

        if (isOk) {
          await _manageCallWhenEndedWithoutMutex(ViewDisplayStatus.ok);
        }
      });

  /// This is the method used to notify the end of the view. It calls [config.callWhenEnded] method
  /// if it hasn't already been done.
  ///
  /// This method isn't protected by the [_whenEndedMutex] mutex.
  Future<void> _manageCallWhenEndedWithoutMutex(ViewDisplayStatus status) async {
    if (_whenEndedCalled) {
      // We already called when ended, nothing to do more
      return;
    }

    _whenEndedCalled = true;
    return config.callWhenEnded(status);
  }

  /// Call [_manageCallWhenEndedWithoutMutex] with the [_whenEndedMutex] mutex.
  Future<void> _manageCallWhenEnded(ViewDisplayStatus status) =>
      _whenEndedMutex.protect(() async => _manageCallWhenEndedWithoutMutex(status));

  @override
  Future<void> close() async {
    await _isOkSub.cancel();

    return super.close();
  }
}
