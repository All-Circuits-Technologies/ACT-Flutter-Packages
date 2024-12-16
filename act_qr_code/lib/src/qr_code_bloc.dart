// Copyright (c) 2020. BMS Circuits

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_qr_code/src/qr_code_event.dart';
import 'package:act_qr_code/src/qr_code_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Bloc for managing Qr Code events
class QrCodeBloc extends Bloc<QrCodeEvent, QrCodeState> {
  static LockUtility _lockUtility = LockUtility();

  QrCodeBloc() : super(QrCodeState.init()) {
    _getPermissions();
  }

  /// Ask permissions for using camera (the widget isn't asking for permission
  /// in iOS)
  Future<void> _getPermissions() async {
    LockEntity lock = await _lockUtility.waitAndLock();

    PermissionStatus status = await Permission.camera.status;

    add(QrCodePermissionGotEvent(permissionStatus: status));

    if (status == PermissionStatus.permanentlyDenied) {
      AppLogger().w("Can't use the camera, the permission has been "
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

    add(QrCodePermissionGotEvent(permissionStatus: status));
    lock.freeLock();
  }

  @override
  Stream<QrCodeState> mapEventToState(QrCodeEvent event) async* {
    if (event is QrCodePermissionGotEvent) {
      yield PermissionResultState(
        previousState: state,
        permissionStatus: event.permissionStatus,
      );
    } else if (event is QrCodeFoundEvent) {
      yield QrCodeFoundState(
        previousState: state,
        found: event.found,
      );
    }
  }
}
