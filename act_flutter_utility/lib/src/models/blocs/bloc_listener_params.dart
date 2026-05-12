// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This class is used to pass the parameters to the BlocListener widget in a more convenient way.
class BlocListenerParams<B extends StateStreamable<S>, S> extends Equatable {
  /// The listener function that will be called when the state changes.
  final BlocWidgetListener<S> listener;

  /// The bloc that will be listened to. If null, the BlocListener will automatically perform a
  /// lookup using [BlocProvider] and the current BuildContext.
  final B? bloc;

  /// An optional condition that determines whether the listener should be called based on the
  /// previous and current state.
  final BlocListenerCondition<S>? listenWhen;

  /// Class constructor
  const BlocListenerParams({required this.listener, this.bloc, this.listenWhen});

  @override
  List<Object?> get props => [listener, bloc, listenWhen];
}
