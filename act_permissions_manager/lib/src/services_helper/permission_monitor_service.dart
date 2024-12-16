// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle_manager/act_life_cycle_manager.dart';
import 'package:act_permissions_manager/src/element/permission_element.dart';
import 'package:act_permissions_manager/src/handlers/permission_handler.dart';
import 'package:act_permissions_manager/src/permissions_manager.dart';
import 'package:act_permissions_manager/src/view_action/permission_view_context.dart';
import 'package:mutex/mutex.dart';
import 'package:permission_handler/permission_handler.dart';

/// This class is used to keep the track of a particular permission
/// The class may also ask for permission and display contextual views to user if needed
class PermissionMonitorService {
  /// Timeout used to wait for the permission update after having asked the user to update the
  /// permission status by himself
  static const openAppSettingGetStatusTimeout = Duration(seconds: 4);

  /// The permission element attached to this service monitor
  final PermissionElement _permissionElement;

  /// The permission handler attached to this service monitor
  final PermissionHandler _permissionHandler;

  /// The lock utility linked to the process of this monitor
  final Mutex _verifyMutex;

  /// Keep in memory the state of the permission
  bool _isGranted;

  /// The permission controller
  final StreamController<bool> _permissionCtrl;

  /// Inform if we have the permission (or not)
  Stream<bool> get hasPermissionStream => _permissionCtrl.stream;

  /// Subscription of the permission status
  late final StreamSubscription<PermissionStatus> _hasPermissionSub;

  /// Class constructor
  PermissionMonitorService._({
    required PermissionsManager permissionsManager,
    required PermissionElement permissionElement,
  })  : _permissionElement = permissionElement,
        _permissionHandler = permissionsManager.getAHandler(permissionElement),
        _isGranted = false,
        _verifyMutex = Mutex(),
        _permissionCtrl = StreamController<bool>.broadcast() {
    _hasPermissionSub = _permissionHandler.statusStream.listen(_onPermission);
  }

  /// Useful to create a [PermissionMonitorService] which allows to watch a particular permission
  static PermissionMonitorService monitorService({
    required PermissionsManager permissionsManager,
    required PermissionElement permissionElement,
  }) =>
      PermissionMonitorService._(
        permissionElement: permissionElement,
        permissionsManager: permissionsManager,
      );

  /// Verify the permission without requesting it to the user
  /// This method has to be called before doing actions which request specific permissions
  Future<bool> verifyBeforeAction() async =>
      ((await _permissionHandler.currentStatus) == PermissionStatus.granted);

  /// Verify the permission and if it's not  requesting it to the user
  /// This method has to be called before doing actions which request specific permissions
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the permissions aren't granted, the
  /// method will ask to display a HMI to inform the user of the necessity to grant the permissions.
  /// If false, no HMI is displayed and we redirect the user to the system permissions page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted
  Future<bool> verifyAndAskBeforeAction({
    bool displayContextualIfNeeded = true,
    bool checkRationale = false,
    bool forceGoToSettings = false,
    bool isAcceptanceCompulsory = false,
  }) async =>
      ((await _verify(
            displayContextualIfNeeded: displayContextualIfNeeded,
            checkRationale: checkRationale,
            forceGoToSettings: forceGoToSettings,
            isAcceptanceCompulsory: isAcceptanceCompulsory,
          )) ==
          PermissionStatus.granted);

  /// Setter for the current permission, if the value has been modified the
  /// new state is sent
  void _setPermission(PermissionStatus permission) {
    final granted = (permission == PermissionStatus.granted);

    if (granted != _isGranted) {
      // We don't emit event if we pass from Denied to Permanently denied
      // (when the granted info hasn't changed)
      _isGranted = granted;
      _permissionCtrl.add(granted);
    }
  }

  /// Called when the permission status is updated
  Future<void> _onPermission(PermissionStatus permissionStatus) async {
    _setPermission(permissionStatus);
  }

  /// Verify the permission and request if needed
  ///
  /// This method is protected by a mutex
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the permissions aren't granted, the
  /// method will ask to display a HMI to inform the user of the necessity to grant the permissions.
  /// If false, no HMI is displayed and we redirect the user to the system permissions page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted
  Future<PermissionStatus> _verify({
    bool displayContextualIfNeeded = true,
    bool checkRationale = false,
    bool forceGoToSettings = false,
    bool isAcceptanceCompulsory = false,
  }) =>
      _verifyMutex.protect(() async => _noMutexSafeVerify(
            displayContextualIfNeeded: displayContextualIfNeeded,
            checkRationale: checkRationale,
            forceGoToSettings: forceGoToSettings,
            isAcceptanceCompulsory: isAcceptanceCompulsory,
          ));

  /// Verify the permission and request if needed
  ///
  /// The method is not protected by a mutex. Most of the time, you have to use the [_verify]
  /// method instead of this one.
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the permissions aren't granted, the
  /// method will ask to display a HMI to inform the user of the necessity to grant the permissions.
  /// If false, no HMI is displayed and we redirect the user to the system permissions page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted
  Future<PermissionStatus> _noMutexSafeVerify({
    bool displayContextualIfNeeded = true,
    bool checkRationale = false,
    bool forceGoToSettings = false,
    bool isAcceptanceCompulsory = false,
  }) async {
    var status = await _permissionHandler.currentStatus;

    if (status == PermissionStatus.granted) {
      return PermissionStatus.granted;
    }

    // Check if user has permanently denied or not (happens when rationale need to be checked)
    if (status == PermissionStatus.denied && checkRationale) {
      final showRationale = await _permissionHandler.shouldShowRationale();
      if (showRationale) {
        status = PermissionStatus.permanentlyDenied;
      }
    }

    final previousStatus = status;
    if (status == PermissionStatus.permanentlyDenied ||
        status == PermissionStatus.restricted) {
      status = await _showPermanentlyDeniedView(
        displayContextualIfNeeded: displayContextualIfNeeded,
      );
    } else {
      // Ask permission, if we leave the app it means that the user has been asked to do
      // something in the OS settings. In that case, we don't want to ask him to go
      // to settings again
      // ignore: use_build_context_synchronously
      status = await _showViewAndAskPermission(
        displayContextualIfNeeded: displayContextualIfNeeded,
        checkRationale: checkRationale,
        isAcceptanceCompulsory: isAcceptanceCompulsory,
      );
    }

    // Still denied then show popup
    if (status == PermissionStatus.permanentlyDenied &&
        previousStatus == PermissionStatus.denied) {
      // ignore: use_build_context_synchronously
      await _showPermanentlyDeniedView(
        displayContextualIfNeeded: displayContextualIfNeeded,
        openAppSetting: false,
      );
    }

    return status;
  }

  /// Show view and ask for permission
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the permissions aren't granted, the
  /// method will ask to display a HMI to inform the user of the necessity to grant the permissions.
  /// If false, no HMI is displayed and we redirect the user to the system permissions page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted
  Future<PermissionStatus> _showViewAndAskPermission({
    bool displayContextualIfNeeded = true,
    bool checkRationale = false,
    bool forceGoToSettings = false,
    bool isAcceptanceCompulsory = false,
  }) async {
    if (!displayContextualIfNeeded) {
      return _permissionHandler.requestPermission(
        checkRationale: checkRationale,
      );
    }

    // Explain why we need permission, the responsibility to ask the permission is delegated to the
    // view
    final viewResult = await globalGetIt()
        .get<ContextualViewsManager>()
        .display<PermissionStatus>(
            context: PermissionViewContext.askPermission(
              element: _permissionElement,
              isAcceptanceCompulsory: isAcceptanceCompulsory,
            ),
            doAction: () async {
              final result = await _noMutexSafeVerify(
                displayContextualIfNeeded: false,
                isAcceptanceCompulsory: isAcceptanceCompulsory,
                checkRationale: checkRationale,
                forceGoToSettings: forceGoToSettings,
              );

              return (result.isGranted, result);
            });

    if (!viewResult.status.isPositiveResult ||
        viewResult.customResult == null) {
      return PermissionStatus.denied;
    }

    return viewResult.customResult!;
  }

  /// Show permanently denied view
  ///
  /// If [openAppSetting] is equals to true, we will offer the possibility to open app setting
  Future<PermissionStatus> _showPermanentlyDeniedView({
    bool displayContextualIfNeeded = true,
    bool openAppSetting = true,
  }) async {
    if (!displayContextualIfNeeded) {
      if (!openAppSetting) {
        return PermissionStatus.permanentlyDenied;
      }

      // Nothing to do
      return _openAppSetting();
    }

    final viewResult =
        await globalGetIt().get<ContextualViewsManager>().display(
              context: PermissionViewContext.informPermanentlyDenied(
                element: _permissionElement,
              ),
              doAction: openAppSetting
                  ? () async {
                      // Go to app settings if we are permanently denied
                      final status = await _openAppSetting();

                      return (status.isGranted, status);
                    }
                  : null,
            );

    if (!viewResult.status.isPositiveResult ||
        viewResult.customResult == null) {
      return PermissionStatus.permanentlyDenied;
    }

    return viewResult.customResult!;
  }

  /// Helpful method to open app settings and waits for the  permission state to be modified by the
  /// system
  Future<PermissionStatus> _openAppSetting() async => WaitUtility.waitForStatus(
        isExpectedStatus: (status) => status.isGranted,
        valueGetter: () async => _permissionHandler.currentStatus,
        statusEmitter: _permissionHandler.statusStream,
        doAction: () async {
          await globalGetIt().get<LifeCycleManager>().waitForegroundApp(
                leaveTheApp: openAppSettings,
              );
          return true;
        },
        timeout: openAppSettingGetStatusTimeout,
      );

  /// Called to close the permission monitor service
  Future<void> close() async {
    final futures = <Future>[
      _permissionCtrl.close(),
      _hasPermissionSub.cancel(),
    ];

    if (_verifyMutex.isLocked) {
      await _verifyMutex.acquire();
      _verifyMutex.release();
    }

    await _permissionHandler.close();

    await Future.wait(futures);
  }
}
