// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_life_cycle_manager/act_life_cycle_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/src/element/permission_element.dart';
import 'package:act_permissions_manager/src/element/permission_element_extension.dart';
import 'package:act_permissions_manager/src/handlers/permission_handler.dart';
import 'package:act_permissions_manager/src/handlers/permission_watcher.dart';
import 'package:act_platform_manager/act_platform_manager.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;

/// Builder for creating the PermissionsManager
class PermissionsBuilder extends ManagerBuilder<PermissionsManager> {
  /// Class constructor with the class construction
  PermissionsBuilder() : super(() => PermissionsManager());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [
        LoggerManager,
        LifeCycleManager,
        PlatformManager,
      ];
}

/// The WiFi manager allows to manage the WiFi features of the mobile
class PermissionsManager extends AbstractManager {
  /// Sometimes a permission request returns "denied" even though we have accepted the permission
  /// (it's a problem with the library). To compensate the problem we try to get the status
  /// multiple times after the request.
  /// The following duration is the time we wait before each try.
  static const deniedRequestGetStatusDuration = Duration(milliseconds: 300);

  /// Sometimes a permission request returns "denied" even though we have accepted the permission
  /// (it's a problem with the library). To compensate the problem we try to get the status
  /// multiple times after the request.
  /// The following is the number of try we do
  static const deniedRequestMaxTryNb = 3;

  /// This map contains all the permission watchers
  late Map<PermissionElement, PermissionWatcher> _watchers;

  /// Class constructor
  PermissionsManager() : super() {
    _watchers = _initWatchers(this);
  }

  /// Init method
  @override
  Future<void> initManager() async {}

  /// Has the user already denied the request
  Future<bool> shouldShowRationale(
    PermissionElement permElem,
  ) async {
    for (final permission in permElem.permissions) {
      final shouldShowRationale = await permission.shouldShowRequestRationale;
      if (shouldShowRationale) {
        // User has already denied this request
        return true;
      }
    }

    return false;
  }

  /// Request the wanted permission, returns the permission status
  ///
  /// If the permission is granted or permanentlyDenied, the method returns
  /// straight away
  Future<permission_handler.PermissionStatus> requestPermission(
    PermissionElement permElem, {
    bool checkRationale = false,
  }) async {
    var status = permission_handler.PermissionStatus.granted;

    for (final permission in permElem.permissions) {
      var tmpStatus = await permission.status;

      switch (tmpStatus) {
        case permission_handler.PermissionStatus.permanentlyDenied:
        case permission_handler.PermissionStatus.granted:
        case permission_handler.PermissionStatus.restricted:
        case permission_handler.PermissionStatus.limited:
        case permission_handler.PermissionStatus.provisional:
          // Nothing can be done
          break;
        case permission_handler.PermissionStatus.denied:
          tmpStatus = await permission.request();
          break;
      }

      var idx = 0;
      while (tmpStatus == permission_handler.PermissionStatus.denied &&
          idx < deniedRequestMaxTryNb) {
        // For some permissions the lib doesn't return right away the correct answer from the
        // request. Therefore, We have to get the status again to have the right answer.
        await Future.delayed(deniedRequestGetStatusDuration);
        tmpStatus = await permission.status;
        ++idx;
      }

      status = _filterPermissions(status, tmpStatus);

      // Check if user has permanently denied or not
      // happens when rationale needs to be checked
      if (status == permission_handler.PermissionStatus.denied &&
          checkRationale) {
        final showRationale = await shouldShowRationale(permElem);
        if (showRationale) {
          status = permission_handler.PermissionStatus.permanentlyDenied;
        }
      }

      if (status == permission_handler.PermissionStatus.permanentlyDenied ||
          status == permission_handler.PermissionStatus.denied ||
          status == permission_handler.PermissionStatus.restricted) {
        // Useless to go forward, the user has already denied a permission
        break;
      }
    }

    // The watchers is initialized with all the possible permission element
    _watchers[permElem]!.setCurrentStatus(status);

    return status;
  }

  /// Return the current status of the permission
  Future<permission_handler.PermissionStatus> getPermission(
    PermissionElement permElem,
  ) async {
    var status = permission_handler.PermissionStatus.granted;

    for (final permission in permElem.permissions) {
      final tmpStatus = await permission.status;
      status = _filterPermissions(status, tmpStatus);

      if (status == permission_handler.PermissionStatus.permanentlyDenied) {
        // Useless to iterate on other permissions, we can't have worse
        break;
      }
    }

    return status;
  }

  /// Test if the permission asked is currently granted
  Future<bool> isGranted(PermissionElement permElem) async =>
      (await getPermission(permElem) ==
          permission_handler.PermissionStatus.granted);

  /// Return a [PermissionHandler] to observe and manage more easily the
  /// permission modifications
  PermissionHandler getAHandler(PermissionElement element) =>
      _watchers[element]!.generateHandler();

  /// Init and create a watcher for each element of the [PermissionElement] enum
  static Map<PermissionElement, PermissionWatcher> _initWatchers(
    PermissionsManager manager,
  ) {
    final map = <PermissionElement, PermissionWatcher>{};

    for (final element in PermissionElement.values) {
      _createAWatcher(map, manager, element);
    }

    return map;
  }

  /// Create a watcher to observe a specific permission modification
  static void _createAWatcher(
    Map<PermissionElement, PermissionWatcher> map,
    PermissionsManager manager,
    PermissionElement element,
  ) {
    map[element] = PermissionWatcher(manager, element);
  }

  permission_handler.PermissionStatus _filterPermissions(
    permission_handler.PermissionStatus permission,
    permission_handler.PermissionStatus otherPermission,
  ) {
    if (permission == permission_handler.PermissionStatus.permanentlyDenied ||
        otherPermission ==
            permission_handler.PermissionStatus.permanentlyDenied) {
      return permission_handler.PermissionStatus.permanentlyDenied;
    }

    if (permission == permission_handler.PermissionStatus.restricted ||
        otherPermission == permission_handler.PermissionStatus.restricted) {
      return permission_handler.PermissionStatus.restricted;
    }

    if (permission == permission_handler.PermissionStatus.denied ||
        otherPermission == permission_handler.PermissionStatus.denied) {
      return permission_handler.PermissionStatus.denied;
    }

    if (permission == permission_handler.PermissionStatus.limited ||
        otherPermission == permission_handler.PermissionStatus.limited) {
      return permission_handler.PermissionStatus.limited;
    }

    return permission;
  }
}
