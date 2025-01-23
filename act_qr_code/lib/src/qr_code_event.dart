// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abstract event for the QrCode bloc
abstract class QrCodeEvent extends Equatable {
  const QrCodeEvent() : super();
}

/// Emitted when a new QrCode has been found
class QrCodeFoundEvent extends QrCodeEvent {
  final bool found;

  const QrCodeFoundEvent({
    required this.found,
  }) : super();

  @override
  List<Object?> get props => [found];
}

/// Emitted when a new permission status is raised
class QrCodePermissionRetrievedEvent extends QrCodeEvent {
  final PermissionStatus permissionStatus;

  const QrCodePermissionRetrievedEvent({
    required this.permissionStatus,
  }) : super();

  @override
  List<Object> get props => [permissionStatus];
}
