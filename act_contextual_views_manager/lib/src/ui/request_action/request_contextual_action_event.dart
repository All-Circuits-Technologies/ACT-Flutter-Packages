// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// Emitted to initialise the request ui bloc
class RequestContextualActionInitEvent extends BlocEventForMixin {
  /// Class constructor
  const RequestContextualActionInitEvent();
}

/// Emitted when the new [isOk] status has been detected
class RequestContextualActionNewStateEvent extends BlocEventForMixin {
  /// The new [isOk] value
  final bool isOk;

  /// Class constructor
  const RequestContextualActionNewStateEvent({
    required this.isOk,
  }) : super();

  @override
  List<Object?> get props => [...super.props, isOk];
}

/// Emitted when we have to ask to user
class RequestContextualActionAskEvent extends BlocEventForMixin {
  /// Class constructor
  const RequestContextualActionAskEvent();
}

/// Emitted when the user has refused to go further or to be requested
class RequestContextualActionRefusedEvent extends BlocEventForMixin {
  /// Class constructor
  const RequestContextualActionRefusedEvent();
}
