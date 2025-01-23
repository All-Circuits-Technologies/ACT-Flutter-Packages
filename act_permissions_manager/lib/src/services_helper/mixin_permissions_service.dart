// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_permissions_manager/src/element/permission_element.dart';
import 'package:act_permissions_manager/src/permissions_manager.dart';
import 'package:act_permissions_manager/src/services_helper/permission_monitor_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Contains useful information to describe the permission to verify
class PermissionConfig extends Equatable {
  /// The permission element
  final PermissionElement element;

  /// Say if we need to check rationale when asking for permission
  final bool whenAskingCheckRationale;

  /// Say if we need to go to settings page when asking for permission
  final bool whenAskingForceRetrievedToSettings;

  /// The permissions list, this permission depends on
  final List<PermissionElement> whenAskingDependsOn;

  /// Class constructor
  const PermissionConfig({
    required this.element,
    this.whenAskingCheckRationale = false,
    this.whenAskingForceRetrievedToSettings = false,
    this.whenAskingDependsOn = const [],
  });

  @override
  List<Object?> get props => [
        element,
        whenAskingCheckRationale,
        whenAskingForceRetrievedToSettings,
        whenAskingDependsOn,
      ];
}

/// This exception is raised when a permission element say it depends of an unknown dependency
class NotKnownDependencyException implements Exception {
  /// The unknown permission element
  PermissionElement permissionElement;

  /// Class constructor
  NotKnownDependencyException(this.permissionElement) : super();
}

/// This contains the dependencies needed by the [MPermissionsService] when using the mixin on
/// AbstractManager
mixin MPermissionsServiceBuilder<T extends AbstractManager> on ManagerBuilder<T> {
  @override
  Iterable<Type> dependsOn() => [PermissionsManager];
}

/// This mixin contains the management of permissions for Managers (you give the permissions linked
/// to what you are doing and this mixin manages the asking and verification if you have the needed
/// permissions)
mixin MPermissionsService on AbstractManager {
  /// The list of the permissions linked
  final Map<PermissionElement, _PermissionContainer> _permissionContainer = {};

  /// The stream controller for the permissions state
  final StreamController<bool> _permissionsCtrl = StreamController<bool>.broadcast();

  /// Returns a stream to watch the permissions state, linked to the [hasPermissions] value
  Stream<bool> get permissionsStream => _permissionsCtrl.stream;

  /// This is equals to true if all the permissions linked to the manager are granted
  bool get hasPermissions {
    for (final permission in _permissionContainer.values) {
      if (!permission.hasPermission) {
        return false;
      }
    }

    return true;
  }

  /// Allow to init the manager
  @override
  Future<void> initManager() async {
    final configs = getPermissionsConfig();

    final dependsOn = <PermissionElement, List<PermissionElement>>{};

    for (final config in configs) {
      _permissionContainer[config.element] = _PermissionContainer(
        element: config.element,
        updatePermission: updatePermission,
        whenAskingCheckRationale: config.whenAskingCheckRationale,
        whenAskingDependsOn: [],
        whenAskingForceGoToSettings: config.whenAskingForceRetrievedToSettings,
      );

      dependsOn[config.element] = config.whenAskingDependsOn;
    }

    for (final depend in dependsOn.entries) {
      final container = _permissionContainer[depend.key]!;

      for (final dependOn in depend.value) {
        final dependContainer = _permissionContainer[dependOn];

        if (dependContainer == null) {
          throw (NotKnownDependencyException(dependOn));
        }

        container.whenAskingDependsOn.add(dependContainer);
      }
    }
  }

  /// Check the permissions, if [askActionToUser] is equal to false, the method only checks the
  /// current permissions statuses
  /// If [askActionToUser] is equal to true, the method do the same thing as
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the permissions aren't granted, the
  /// method will ask to display a HMI to inform the user of the necessity to grant the permissions.
  /// If false, no HMI displayed is and we redirect the user to the system permissions page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted
  /// [checkAndAskPermissions]
  Future<bool> checkPermissions({
    bool askActionToUser = true,
    bool displayContextualIfNeeded = true,
    bool isAcceptanceCompulsory = false,
  }) async {
    if (askActionToUser) {
      return checkAndAskPermissions(
        displayContextualIfNeeded: displayContextualIfNeeded,
        isAcceptanceCompulsory: isAcceptanceCompulsory,
      );
    }

    for (final container in _permissionContainer.values) {
      if (!container.hasPermission) {
        return false;
      }
    }

    return true;
  }

  /// This method checks and asks for permissions (if needed), it respects the permission
  /// dependencies order
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the permissions aren't granted, the
  /// method will ask to display a HMI to inform the user of the necessity to grant the permissions.
  /// If false, no HMI displayed is and we redirect the user to the system permissions page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted
  Future<bool> checkAndAskPermissions({
    bool displayContextualIfNeeded = true,
    bool isAcceptanceCompulsory = false,
  }) async {
    final alreadyChecked = <PermissionElement>[];
    var tmpHasPermission = true;

    // We loop until we test all the permissions
    while (alreadyChecked.length != _permissionContainer.length) {
      for (final containerEntry in _permissionContainer.entries) {
        if (alreadyChecked.contains(containerEntry.key)) {
          // Already tested, we continue
          continue;
        }

        var dependenciesAlreadyTested = true;

        for (final dependsOn in containerEntry.value.whenAskingDependsOn) {
          if (!alreadyChecked.contains(dependsOn.element)) {
            dependenciesAlreadyTested = false;
            break;
          }
        }

        if (!dependenciesAlreadyTested) {
          // We go forward
          continue;
        }

        if (!(await containerEntry.value.checkAndAskPermission(
          displayContextualIfNeeded: displayContextualIfNeeded,
          isAcceptanceCompulsory: isAcceptanceCompulsory,
        ))) {
          // At least one element hasn't the permission, but we continue to test all
          tmpHasPermission = false;
        }

        alreadyChecked.add(containerEntry.key);
      }
    }

    return tmpHasPermission;
  }

  /// This method is called by all the [_PermissionContainer] linked to this service, to verify the
  /// global permission status
  /// [element] represents the [_PermissionContainer] caller and [newValue], the new permission
  /// value
  /// Returns true if [hasPermissions] has been updated in this method call
  @protected
  Future<bool> updatePermission(PermissionElement element, bool newValue) async {
    final previousGranted = hasPermissions;

    _permissionContainer[element]!.hasPermission = newValue;

    final newGranted = hasPermissions;

    if (previousGranted != newGranted) {
      _permissionsCtrl.add(newGranted);
    }

    return (previousGranted != newGranted);
  }

  /// Get the permissions configuration linked to this mixin permissions service
  @protected
  List<PermissionConfig> getPermissionsConfig();

  @override
  Future<void> dispose() async {
    final futures = <Future>[
      super.dispose(),
      _permissionsCtrl.close(),
    ];

    for (final container in _permissionContainer.values) {
      futures.add(container.close());
    }

    await Future.wait(futures);
  }
}

/// Represents a permission element to test in the permissions service
class _PermissionContainer {
  /// The permission element linked to this container
  final PermissionElement element;

  /// Say if we need to check rationale when asking for permission
  final bool whenAskingCheckRationale;

  /// Say if we need to go to settings page when asking for permission
  final bool whenAskingForceGoToSettings;

  /// The permissions list, this permission depends on
  final List<_PermissionContainer> whenAskingDependsOn;

  /// The permission subscription linked to the permission manager listener
  late final StreamSubscription _permissionSub;

  /// The permission monitor service linked to this permission
  late final PermissionMonitorService _permissionMonitorService;

  /// The callback to call when the permission has to be updated
  final void Function(PermissionElement, bool) updatePermission;

  /// State of the linked permission
  bool hasPermission;

  /// Class constructor
  _PermissionContainer({
    required this.element,
    required this.updatePermission,
    required this.whenAskingForceGoToSettings,
    required this.whenAskingCheckRationale,
    required this.whenAskingDependsOn,
  }) : hasPermission = false {
    final permissionManager = globalGetIt().get<PermissionsManager>();

    _permissionMonitorService = PermissionMonitorService.monitorService(
      permissionsManager: permissionManager,
      permissionElement: element,
    );

    _permissionSub =
        permissionManager.getAHandler(element).statusStream.listen(_onPermissionStatusUpdated);
  }

  /// Check and ask for permission
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the permissions aren't granted, the
  /// method will ask to display a HMI to inform the user of the necessity to grant the permissions.
  /// If false, no HMI displayed is and we redirect the user to the system permissions page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted
  Future<bool> checkAndAskPermission({
    bool displayContextualIfNeeded = true,
    bool isAcceptanceCompulsory = false,
  }) async {
    var tmpHasPermission = hasPermission;

    var dependsOnPermission = true;

    for (final container in whenAskingDependsOn) {
      if (!container.hasPermission) {
        dependsOnPermission = false;
      }
    }

    if (dependsOnPermission && !tmpHasPermission) {
      tmpHasPermission = await _permissionMonitorService.verifyAndAskBeforeAction(
        displayContextualIfNeeded: displayContextualIfNeeded,
        checkRationale: whenAskingCheckRationale,
        forceGoToSettings: whenAskingForceGoToSettings,
        isAcceptanceCompulsory: isAcceptanceCompulsory,
      );

      updatePermission(element, tmpHasPermission);
    }

    return tmpHasPermission;
  }

  /// Called when the permission status is updated
  Future<void> _onPermissionStatusUpdated(PermissionStatus status) async {
    final permissionGranted = (status == PermissionStatus.granted);
    updatePermission(element, permissionGranted);
  }

  Future<void> close() async {
    await Future.wait([
      _permissionSub.cancel(),
      _permissionMonitorService.close(),
    ]);
  }
}
