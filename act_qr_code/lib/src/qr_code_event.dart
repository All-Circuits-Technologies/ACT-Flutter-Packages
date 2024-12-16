// Copyright (c) 2020. BMS Circuits

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

/// Abstract event for the QrCode bloc
@immutable
abstract class QrCodeEvent extends Equatable {
  QrCodeEvent() : super();
}

/// Emitted when a new QrCode has been found
@immutable
class QrCodeFoundEvent extends QrCodeEvent {
  final bool found;

  QrCodeFoundEvent({
    @required bool found,
  })  : assert(found != null),
        found = found,
        super();

  @override
  List<Object> get props => [found];
}

/// Emitted when a new permission status is raised
@immutable
class QrCodePermissionGotEvent extends QrCodeEvent {
  final PermissionStatus permissionStatus;

  QrCodePermissionGotEvent({
    @required PermissionStatus permissionStatus,
  })  : assert(permissionStatus != null),
        permissionStatus = permissionStatus,
        super();

  @override
  List<Object> get props => [permissionStatus];
}
