// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_qr_code/src/qr_code_event.dart';
import 'package:act_qr_code/src/qr_code_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bloc for managing Qr Code events
class QrCodeBloc extends Bloc<QrCodeEvent, QrCodeState> {
  /// This is the lock utility
  static final _lockUtility = LockUtility();

  /// Class constructor
  QrCodeBloc() : super(const QrCodeState.init()) {
    on(_onQrCodePermissionRetrievedEvent);
    on(_onQrCodeFoundEvent);

    unawaited(_getPermissions());
  }

  /// Ask permissions for using camera (the widget isn't asking for permission
  /// in iOS)
  Future<void> _getPermissions() async {
    final lock = await _lockUtility.waitAndLock();

    var status = await Permission.camera.status;

    add(QrCodePermissionRetrievedEvent(permissionStatus: status));

    if (status == PermissionStatus.permanentlyDenied) {
      appLogger().w("Can't use the camera, the permission has been "
          "permanently denied");
      lock.freeLock();
      return;
    }

    if (status == PermissionStatus.granted) {
      // Nothing to do
      lock.freeLock();
      return;
    }

    status = await Permission.camera.request();

    add(QrCodePermissionRetrievedEvent(permissionStatus: status));
    lock.freeLock();
  }

  Future<void> _onQrCodePermissionRetrievedEvent(
      QrCodePermissionRetrievedEvent event, Emitter<QrCodeState> emitter) async {
    emitter.call(PermissionResultState(
      previousState: state,
      permissionStatus: event.permissionStatus,
    ));
  }

  Future<void> _onQrCodeFoundEvent(QrCodeFoundEvent event, Emitter<QrCodeState> emitter) async {
    emitter.call(QrCodeFoundState(
      previousState: state,
      found: event.found,
    ));
  }
}
