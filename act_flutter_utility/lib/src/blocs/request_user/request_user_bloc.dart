// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_flutter_utility/src/blocs/request_user/request_user_event.dart';
import 'package:act_flutter_utility/src/blocs/request_user/request_user_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This callback is called to request the user and knows if it's ok or not
typedef RequestUserCallback = FutureOr<bool> Function();

/// This bloc is used to request the user and waits for the associated status update
class RequestUserUiBloc extends Bloc<RequestUserUiEvent, RequestUserUiState> {
  /// Subscription to the isOk stream
  late final StreamSubscription _isOkSub;

  /// Called when the action is accepted by the user
  final VoidCallback actionIfAccepted;

  /// The method used to request the user
  /// Returns true if the user is ok
  final RequestUserCallback _requestUser;

  /// Class constructor
  ///
  /// [isOkCallback] is used to know the current state
  RequestUserUiBloc({
    required this.actionIfAccepted,
    required bool Function() isOkCallback,
    required RequestUserCallback requestUser,
    required Stream<bool> isOkStream,
  })  : _requestUser = requestUser,
        super(RequestUserUiInitState(
          isOk: isOkCallback(),
        )) {
    on<RequestUserUiInitEvent>(_onInitCallback);
    on<RequestUserUiNewStateEvent>(_onIsOkUpdated);
    on<RequestUserUiAskEvent>(_onRequestUser);

    _isOkSub = isOkStream.listen(_onIsOkStatus);

    add(const RequestUserUiInitEvent());
  }

  /// Called at the bloc initialisation
  Future<void> _onInitCallback(
    RequestUserUiInitEvent event,
    Emitter<RequestUserUiState> emitter,
  ) async {
    if (state.isOk) {
      // Nothing more to do
      actionIfAccepted();
      return;
    }

    emitter.call(RequestUserUiLoadingState(
      previousState: state,
      loading: false,
    ));
  }

  /// Called when the 'is ok' changes
  void _onIsOkStatus(bool isOk) {
    add(RequestUserUiNewStateEvent(isOk: isOk));
  }

  /// Called to update the state with the new [event.isOk] status
  void _onIsOkUpdated(
    RequestUserUiNewStateEvent event,
    Emitter<RequestUserUiState> emitter,
  ) {
    emitter.call(RequestUserUiUpdateState(
      previousState: state,
      isOk: event.isOk,
    ));
  }

  /// Called to request the user
  Future<void> _onRequestUser(
    RequestUserUiAskEvent event,
    Emitter<RequestUserUiState> emitter,
  ) async {
    emitter.call(RequestUserUiLoadingState(
      previousState: state,
      loading: true,
    ));

    final isOk = await _requestUser();

    emitter.call(RequestUserUiUpdateState(
      previousState: state,
      isOk: isOk,
      loading: false,
    ));

    if (isOk) {
      actionIfAccepted();
    }
  }

  @override
  Future<void> close() async {
    await _isOkSub.cancel();

    return super.close();
  }
}
