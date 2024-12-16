// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

/// Default state for QrCode bloc
class QrCodeState extends Equatable {
  /// Represents the current permission status
  final PermissionStatus? permStatus;

  /// Say if the QrCode has been found
  final bool found;

  QrCodeState({
    required QrCodeState previousState,
    required PermissionStatus? permissionStatus,
    required bool? found,
  })  : assert(permissionStatus != null || previousState.permStatus != null,
            "The state can't have a Permission status when calling this constructor"),
        permStatus = permissionStatus ?? previousState.permStatus,
        found = found ?? previousState.found,
        super();

  const QrCodeState.init()
      : permStatus = null,
        found = false,
        super();

  @override
  List<Object?> get props => [permStatus, found];
}

/// Represents the state when a right QrCode has been found
class QrCodeFoundState extends QrCodeState {
  QrCodeFoundState({
    required super.previousState,
    required bool super.found,
  }) : super(permissionStatus: null);
}

/// Represents the permission result state
class PermissionResultState extends QrCodeState {
  PermissionResultState({
    required super.previousState,
    required PermissionStatus super.permissionStatus,
  }) : super(found: null);
}
