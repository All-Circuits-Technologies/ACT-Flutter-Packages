// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';
import 'dart:ui';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_life_cycle_manager/act_life_cycle_manager.dart';
import 'package:act_permissions_manager/src/element/permission_element.dart';
import 'package:act_permissions_manager/src/handlers/permission_handler.dart';
import 'package:act_permissions_manager/src/permissions_manager.dart';
import 'package:mutex/mutex.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:rxdart/rxdart.dart';

/// This class allows to watch the modifications done on a specific permission
///
/// Each time the application life cycle changes, this test the permission
/// linked
///
/// The watcher doesn't observe the permission modification if no one uses the
/// watcher.
class PermissionWatcher extends SharedWatcher<PermissionHandler> {
  final PermissionElement element;
  final StreamController<permission_handler.PermissionStatus> _currentStatusCtrl;
  final PermissionsManager _permissionsManager;
  final ReadWriteMutex _permissionMutex;

  /// [BehaviorSubject] of is lifecycle currently inside the application
  final StreamController<bool> _isInsideAppCtrl;

  /// True if we are currently inside the application
  bool _isInsideApp;

  /// Permission current status
  permission_handler.PermissionStatus? _currentStatus;

  /// This is the stream subscription of the life cycle
  StreamSubscription<AppLifecycleState?>? _lifeCycleSub;

  /// This is the stream linked to the [isInsideApp] property
  Stream<bool> get isInsideAppStream => _isInsideAppCtrl.stream;

  /// Returns true if we are currently inside the app
  bool get isInsideApp => _isInsideApp;

  /// Return the current [permission_handler.PermissionStatus] status
  StreamController<permission_handler.PermissionStatus> get currentStatusCtrl => _currentStatusCtrl;

  /// Get the current [permission_handler.PermissionStatus]
  Future<permission_handler.PermissionStatus> get status => _permissionMutex.protectRead(() async {
        if (_currentStatus == null) {
          await _checkPermissionAndSetStatus();
        }

        // Check permission set the current status to a value (it can't be null);
        // therefore at this step _currentStatus can't be null
        return _currentStatus!;
      });

  /// Class constructor
  PermissionWatcher(PermissionsManager permissionsManager, this.element)
      : _currentStatusCtrl = StreamController.broadcast(),
        _permissionsManager = permissionsManager,
        _permissionMutex = ReadWriteMutex(),
        _isInsideApp = true,
        _isInsideAppCtrl = StreamController<bool>.broadcast(),
        super();

  void _setInsideApp(bool newValue) {
    if (_isInsideApp != newValue) {
      _isInsideApp = newValue;
      _isInsideAppCtrl.add(newValue);
    }
  }

  /// Set the current known status
  /// If the value has changed, this will emit the new status via
  /// [_currentStatusCtrl]
  void setCurrentStatus(permission_handler.PermissionStatus tmpStatus) {
    if (tmpStatus != _currentStatus) {
      _currentStatus = tmpStatus;
      if (!_currentStatusCtrl.isClosed) {
        _currentStatusCtrl.add(tmpStatus);
      }
    }
  }

  /// Generate a handler to manage the permission watching
  @override
  PermissionHandler generateHandler() => PermissionHandler(this);

  /// Called when there is no handler and one is created
  @override
  Future<void> atFirstHandler() async {
    _lifeCycleSub =
        globalGetIt().get<LifeCycleManager>().lifeCycleStream.listen(_onLifeCycleStateUpdate);

    return _checkPermissionAndSetStatus();
  }

  /// Called when the last handler is closed
  @override
  Future<void> whenNoMoreHandler() async {
    if (_lifeCycleSub != null) {
      await _lifeCycleSub!.cancel();
      _lifeCycleSub = null;
    }
  }

  /// Check if user has already denied request or not
  Future<bool> shouldShowRationale() => _permissionMutex.protectWrite(() async =>
      // The set to current status is already done in the request permission
      // method
      _permissionsManager.shouldShowRationale(element));

  /// Call to request the permission
  Future<permission_handler.PermissionStatus> requestPermission({
    bool checkRationale = false,
  }) =>
      _permissionMutex.protectWrite(() async =>
          // The set to current status is already done in the request permission
          // method
          _permissionsManager.requestPermission(
            element,
            checkRationale: checkRationale,
          ));

  /// Get the current permission status and set the current status
  Future<void> _checkPermissionAndSetStatus({
    bool hasLeavedTheApp = false,
  }) async {
    var perm = await _permissionsManager.getPermission(element);

    if (hasLeavedTheApp) {
      var idx = 0;
      while (perm == permission_handler.PermissionStatus.denied &&
          idx < PermissionsManager.deniedRequestMaxTryNb) {
        // After having left the app, the permission may take some times to be updated, that's why we
        // wait some times to get the right value
        await Future.delayed(PermissionsManager.deniedRequestGetStatusDuration);
        perm = await _permissionsManager.getPermission(element);
        ++idx;
      }
    }

    setCurrentStatus(perm);
  }

  /// Called when the life cycle state of the app has been updated
  Future<void> _onLifeCycleStateUpdate(AppLifecycleState? state) async {
    final tmpIsInsideApp = _guessNewInsideAppStatus(state);
    // Check permission is we were outside of app (does not count pop-up)
    if (tmpIsInsideApp != _isInsideApp) {
      _setInsideApp(tmpIsInsideApp);

      if (tmpIsInsideApp) {
        await _checkPermissionAndSetStatus(hasLeavedTheApp: true);
      }
    }
  }

  /// The method guess if we are currently inside or outside the app
  ///
  /// There is a threshold in the guessing, if we were outside the app, the only status which tells
  /// us that we are in, it's: [AppLifecycleState.resumed].
  /// If we were inside the app, the only status which tells us that we are out, it's:
  /// [AppLifecycleState.paused]
  bool _guessNewInsideAppStatus(AppLifecycleState? state) {
    if (_isInsideApp && (state == AppLifecycleState.paused)) {
      // That means, we have leaved the app
      return false;
    }

    if (!_isInsideApp && (state == AppLifecycleState.resumed)) {
      // That means we went back to the app
      return true;
    }

    return _isInsideApp;
  }

  /// Call this method to close the listening of the Permission watcher
  @override
  Future<void> close() async {
    final futures = <Future<void>>[];

    if (_lifeCycleSub != null) {
      futures.add(_lifeCycleSub!.cancel());
    }

    futures.add(_currentStatusCtrl.close());

    await Future.wait(futures);

    await _isInsideAppCtrl.close();
  }
}
