// Copyright (c) 2020. BMS Circuits

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

/// Default state for QrCode bloc
@immutable
class QrCodeState extends Equatable {
  /// Represents the current permission status
  final PermissionStatus permStatus;

  /// Say if the QrCode has been found
  final bool found;

  QrCodeState({
    @required QrCodeState previousState,
    @required PermissionStatus permissionStatus,
    @required bool found,
  })  : assert(previousState != null),
        assert(permissionStatus != null || previousState.permStatus != null),
        assert(found != null || previousState.found != null),
        permStatus = permissionStatus ?? previousState.permStatus,
        found = found ?? previousState.found,
        super();

  QrCodeState.init()
      : permStatus = PermissionStatus.undetermined,
        found = false,
        super();

  @override
  List<Object> get props => [permStatus];
}

/// Represents the state when a right QrCode has been found
@immutable
class QrCodeFoundState extends QrCodeState {
  QrCodeFoundState({
    @required QrCodeState previousState,
    @required bool found,
  }) : super(
          previousState: previousState,
          found: found,
          permissionStatus: null,
        );
}

/// Represents the permission result state
@immutable
class PermissionResultState extends QrCodeState {
  PermissionResultState({
    @required QrCodeState previousState,
    @required PermissionStatus permissionStatus,
  }) : super(
          previousState: previousState,
          found: null,
          permissionStatus: permissionStatus,
        );
}
