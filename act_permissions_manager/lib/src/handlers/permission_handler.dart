// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_permissions_manager/src/element/permission_element.dart';
import 'package:act_permissions_manager/src/handlers/permission_watcher.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;

/// Handler linked to a permission element
///
/// This allows to get the current status of a permission (and also to request)
/// This emits a status when a modification is detected
///
/// IMPORTANT: when you no longer need this class, call its close method!
class PermissionHandler extends SharedHandler {
  /// This getter is used to cast the inner watcher to the one given
  PermissionWatcher get _castWatcher => watcher as PermissionWatcher;

  /// This getter is used to get the [PermissionElement] attached to the watcher
  PermissionElement get permissionElement => _castWatcher.element;

  /// Get the current permission status
  Future<permission_handler.PermissionStatus> get currentStatus async => _castWatcher.status;

  /// Request the permission (if needed)
  Stream<bool> get isInsideAppStream => _castWatcher.isInsideAppStream;

  /// Request the permission (if needed)
  Future<permission_handler.PermissionStatus> requestPermission({
    bool checkRationale = false,
  }) async =>
      _castWatcher.requestPermission(checkRationale: checkRationale);

  /// Check if user has already denied request or not
  Future<bool> shouldShowRationale() async => _castWatcher.shouldShowRationale();

  /// Stream which emits elements when the status of the permission has been
  /// detected has changed
  Stream<permission_handler.PermissionStatus> get statusStream =>
      _castWatcher.currentStatusCtrl.stream;

  /// Class constructor
  PermissionHandler(SharedWatcher watcher) : super(watcher);
}
