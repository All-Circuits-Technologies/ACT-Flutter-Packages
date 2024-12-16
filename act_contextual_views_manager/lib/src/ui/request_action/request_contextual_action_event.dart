// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Abstract event for the request user process
abstract class RequestContextualActionEvent extends Equatable {
  /// Class constructor
  const RequestContextualActionEvent();
}

/// Emitted to initialise the request ui bloc
class RequestContextualActionInitEvent extends RequestContextualActionEvent {
  /// Class constructor
  const RequestContextualActionInitEvent();

  @override
  List<Object?> get props => [];
}

/// Emitted when the new [isOk] status has been detected
class RequestContextualActionNewStateEvent extends RequestContextualActionEvent {
  /// The new [isOk] value
  final bool isOk;

  /// Class constructor
  const RequestContextualActionNewStateEvent({
    required this.isOk,
  }) : super();

  @override
  List<Object?> get props => [isOk];
}

/// Emitted when we have to ask to user
class RequestContextualActionAskEvent extends RequestContextualActionEvent {
  /// Class constructor
  const RequestContextualActionAskEvent();

  @override
  List<Object?> get props => [];
}

/// Emitted when the user has refused to go further or to be requested
class RequestContextualActionRefusedEvent extends RequestContextualActionEvent {
  /// Class constructor
  const RequestContextualActionRefusedEvent();

  @override
  List<Object?> get props => [];
}
