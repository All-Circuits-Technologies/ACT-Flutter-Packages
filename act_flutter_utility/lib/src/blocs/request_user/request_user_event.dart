// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Abstract event for the request user process
abstract class RequestUserUiEvent extends Equatable {
  /// Class constructor
  const RequestUserUiEvent();
}

/// Emitted to initialise the request ui bloc
class RequestUserUiInitEvent extends RequestUserUiEvent {
  /// Class constructor
  const RequestUserUiInitEvent();

  @override
  List<Object?> get props => [];
}

/// Emitted when the new [isOk] status has been detected
class RequestUserUiNewStateEvent extends RequestUserUiEvent {
  /// The new [isOk] value
  final bool isOk;

  /// Class constructor
  const RequestUserUiNewStateEvent({
    required this.isOk,
  }) : super();

  @override
  List<Object?> get props => [isOk];
}

/// Emitted when we have to ask to user
class RequestUserUiAskEvent extends RequestUserUiEvent {
  /// Class constructor
  const RequestUserUiAskEvent();

  @override
  List<Object?> get props => [];
}
