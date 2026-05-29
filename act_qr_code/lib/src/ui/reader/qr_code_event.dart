// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abstract event for the QrCode bloc
abstract class QrCodeEvent extends Equatable {
  /// Event constructor
  const QrCodeEvent() : super();
}

/// Emitted when a new QrCode has been found
class QrCodeFoundEvent extends QrCodeEvent {
  /// True if the QR code is found
  final bool found;

  /// Class constructor
  const QrCodeFoundEvent({
    required this.found,
  }) : super();

  /// Class properties
  @override
  List<Object?> get props => [found];
}

/// Emitted when a new permission status is raised
class QrCodePermissionRetrievedEvent extends QrCodeEvent {
  /// This is the retrieved permission status
  final PermissionStatus permissionStatus;

  /// Class constructor
  const QrCodePermissionRetrievedEvent({
    required this.permissionStatus,
  }) : super();

  /// Class properties
  @override
  List<Object> get props => [permissionStatus];
}
