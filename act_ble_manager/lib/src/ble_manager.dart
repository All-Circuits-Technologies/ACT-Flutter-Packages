// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_ble_manager/src/gap/ble_gap_service.dart';
import 'package:act_ble_manager/src/gatt/ble_gatt_service.dart';
import 'package:act_ble_manager/src/mixins/mixin_ble_env.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_enable_service_utility/act_enable_service_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_permissions_manager/act_permissions_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

/// Builder for creating the BleManager
class BleBuilder<E extends MixinBleEnv> extends ManagerBuilder<BleManager<E>>
    with MPermissionsServiceBuilder {
  /// A factory to create a manager instance
  BleBuilder() : super(() => BleManager<E>());

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager, E, ...super.dependsOn()];
}

/// This class manages everything related to Bluetooth Low energy
class BleManager<E extends MixinBleEnv> extends AbstractManager
    with MPermissionsService, MEnableService {
  /// This timeout is used when we are enabling the BLE
  static const _enableTimeout = Duration(seconds: 10);

  /// This is the logs category to use for the BLE manager and its dependencies
  static const _bleLogCategory = "ble";

  /// This is the flutter ble instance
  final FlutterReactiveBle _flutterBle;

  /// This is the service which manages everything linked to the GATT service
  late final BleGattService bleGattService;

  /// This is the service which manages everything linked to the GAP service
  late final BleGapService bleGapService;

  /// The logs helper linked to the BLE manager
  late final LogsHelper logsHelper;

  /// This is the controller of the BLE re-init stream
  final StreamController<void> _bleReInitCtrl;

  /// This allows to receive an event when the BLE lib is reinitialized
  Stream<void> get libReInitStream => _bleReInitCtrl.stream;

  /// This is the subscription for the BLE status
  StreamSubscription<BleStatus>? _bleStatusSub;

  /// [BleManager] constructor
  BleManager()
      : _flutterBle = FlutterReactiveBle(),
        _bleReInitCtrl = StreamController<void>.broadcast() {
    bleGapService = BleGapService(bleManager: this, flutterReactiveBle: _flutterBle);
    bleGattService = BleGattService(bleManager: this, flutterReactiveBle: _flutterBle);
    _bleStatusSub = _flutterBle.statusStream.listen(_onBleStatusUpdated);
    _onBleStatusUpdated(_flutterBle.status);
  }

  /// Init manager
  @override
  Future<void> initManager() async {
    await super.initManager();

    logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _bleLogCategory,
    );

    await bleGapService.initService();

    // We get the "display scanned device in logs" information from env manager and set it to the
    // GAP service
    bleGapService.displayScannedDeviceInLogs =
        globalGetIt().get<E>().displayScannedDeviceInLogs.load();

    await bleGattService.initService();
  }

  /// Called after the view system is loaded
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    // In that case, the build context can be accessed through async method
    // ignore: use_build_context_synchronously
    await bleGapService.initAfterView(context);
    // ignore: use_build_context_synchronously
    await bleGattService.initAfterView(context);
  }

  /// Manage the enabling of BLE
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the service is not enabled, the method
  /// will ask to display a HMI to inform the user of the necessity to enable the service. If false,
  /// no HMI displayed is and we redirect the user to the system activation page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the service is disabled
  @override
  Future<bool> askForEnabling({
    bool isAcceptanceCompulsory = false,
    bool displayContextualIfNeeded = true,
  }) async {
    if (isEnabled || _flutterBle.status == BleStatus.ready) {
      // Nothing to do more
      // We set to true, in case the status hasn't been received correctly
      setEnabled(true);
      return true;
    }

    // We wait to receive a BLE status ready
    final tmpStatus = await _manageServiceEnabling(
      isAcceptanceCompulsory: isAcceptanceCompulsory,
      displayContextualIfNeeded: displayContextualIfNeeded,
    );

    setEnabled(tmpStatus == BleStatus.ready);

    return isEnabled;
  }

  /// Manage the service enabling by asking the user to do the right thing
  ///
  /// This method is reentrant if multiple services enabling has to be asked to user
  ///
  /// If [displayContextualIfNeeded] is equals to true and if the service is not enabled, the method
  /// will ask to display a HMI to inform the user of the necessity to enable the service. If false,
  /// no HMI displayed is and we redirect the user to the system activation page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the service is disabled
  Future<BleStatus> _manageServiceEnabling({
    bool isAcceptanceCompulsory = false,
    bool displayContextualIfNeeded = true,
  }) async {
    final bleStatus = _flutterBle.status;

    if (bleStatus == BleStatus.unauthorized) {
      logsHelper.w("Permissions are not granted for BLE, we can't enable it");
      return bleStatus;
    }

    if (bleStatus == BleStatus.unsupported) {
      logsHelper.w("There is no bluetooth on this device");
      return bleStatus;
    }

    AppSettingsType settingsType;
    EnableServiceViewContext? viewContext;

    if (bleStatus == BleStatus.locationServicesDisabled) {
      viewContext = EnableServiceViewContext(
        element: EnableServiceElement.bleLocation,
        isAcceptanceCompulsory: isAcceptanceCompulsory,
      );

      settingsType = AppSettingsType.location;
    } else {
      // In that case, we use the default view context
      settingsType = AppSettingsType.bluetooth;
    }

    // We request the user to ask him to enable the BLE service
    final dialogResult = await requestUser<BleStatus>(
        isAcceptanceCompulsory: isAcceptanceCompulsory,
        displayContextualIfNeeded: displayContextualIfNeeded,
        overrideContext: viewContext,
        manageEnabling: () async {
          // We wait to receive a BLE status ready
          var tmpStatus = await _openAppSettingAndWaitForBleStatus(
            settingsType: settingsType,
            isExpectedStatus: (status) => status == BleStatus.ready,
          );

          if (bleStatus != tmpStatus &&
              (tmpStatus == BleStatus.locationServicesDisabled ||
                  tmpStatus == BleStatus.poweredOff)) {
            // We do this in case where both location and BLE services are disabled
            /* TODO(brolandeau): I haven't tested this case, I'm not sure it's doing what we expect
                                 (open a new contextual view for the other service) */
            tmpStatus = await _manageServiceEnabling(
              isAcceptanceCompulsory: isAcceptanceCompulsory,
              displayContextualIfNeeded: displayContextualIfNeeded,
            );
          }

          return (tmpStatus == BleStatus.ready, tmpStatus);
        });

    if (dialogResult.customResult == null) {
      assert(
          false,
          "The view used to request the user hasn't returned the service status as "
          "expected, it's a problem of development");
      appLogger().w("The view used to request the user hasn't returned the permission status");
      return BleStatus.unknown;
    }

    return dialogResult.customResult!;
  }

  /// Override the default [checkAndAskPermissions] to wait for the BLE status update before
  /// returning
  @override
  Future<bool> checkAndAskPermissions({
    bool displayContextualIfNeeded = true,
    bool isAcceptanceCompulsory = false,
  }) async {
    if (!(await super.checkAndAskPermissions(
      displayContextualIfNeeded: displayContextualIfNeeded,
      isAcceptanceCompulsory: isAcceptanceCompulsory,
    ))) {
      return false;
    }

    // We wait to receive a BLE status different of unauthorized before continue
    await _waitForStatus(isExpectedStatus: (status) => status != BleStatus.unauthorized);

    return true;
  }

  /// This method checks and asks for permissions (if needed) and for service activation
  ///
  /// Better to use this method instead of calling [checkAndAskPermissions] and
  /// [checkAndAskForEnabling] separately; because the method waits for the permissions updates
  /// before verifying for the service state
  ///
  /// if [askActionsToUser] is equal to true, the method asks their permissions to the user if
  /// needed
  /// if [askActionsToUser] is equal to false, the method only checks for the current statuses
  ///
  /// If [displayContextualIfNeeded] is equals to true, if the permissions aren't granted and if the
  /// service is not enabled, the method will ask to display a HMI to inform the user of the
  /// necessity to grant the permissions and enable the service.
  /// If false, no HMI displayed is and we redirect the user to the system permissions page or
  /// activation page.
  ///
  /// If [isAcceptanceCompulsory] and if [displayContextualIfNeeded] are both equals to true, the
  /// displayed HMI will stay up as long as the permissions aren't granted or the service is
  /// disabled.
  Future<bool> checkAndAskForPermissionsAndServices({
    bool askActionsToUser = true,
    bool displayContextualIfNeeded = true,
    bool isAcceptanceCompulsory = false,
  }) async {
    if (!askActionsToUser) {
      return hasPermissions && isEnabled;
    }

    if (!await checkAndAskPermissions(
      displayContextualIfNeeded: displayContextualIfNeeded,
      isAcceptanceCompulsory: isAcceptanceCompulsory,
    )) {
      return false;
    }

    return checkAndAskForEnabling(
      isAcceptanceCompulsory: isAcceptanceCompulsory,
      displayContextualIfNeeded: displayContextualIfNeeded,
    );
  }

  /// Useful method to wait for a particular flutter BLE status after doing some action on the
  /// permissions or BLE service state
  ///
  /// Because the BLE service activation or permissions update may take some time to be acknowledged
  /// by the lib, they advise to listen [_flutterBle.statusStream] and waits for events to have the
  /// right status after an action.
  Future<BleStatus> _waitForStatus({
    required bool Function(BleStatus) isExpectedStatus,
  }) =>
      WaitUtility.waitForStatus(
        isExpectedStatus: isExpectedStatus,
        statusEmitter: _flutterBle.statusStream,
        valueGetter: () => _flutterBle.status,
        timeout: _enableTimeout,
      );

  /// This method is useful to open an app setting and wait for the ble status update before
  /// returning
  Future<BleStatus> _openAppSettingAndWaitForBleStatus({
    required bool Function(BleStatus) isExpectedStatus,
    required AppSettingsType settingsType,
  }) =>
      MEnableService.openAppSettingAndWaitForUpdate<BleStatus>(
        isExpectedStatus: isExpectedStatus,
        settingsType: settingsType,
        statusEmitter: _flutterBle.statusStream,
        valueGetter: () => _flutterBle.status,
        timeout: _enableTimeout,
      );

  /// Get the service element type
  @override
  EnableServiceElement getElement() => EnableServiceElement.ble;

  /// Get the config linked to the permissions
  @override
  List<PermissionConfig> getPermissionsConfig() => [
        const PermissionConfig(
          element: PermissionElement.ble,
        )
      ];

  /// This method allows to reinitialize the Flutter BLE lib
  ///
  /// If a scan was processing, it will restart it
  Future<void> reInitFlutterBle() async {
    await _flutterBle.deinitialize();
    await _flutterBle.initialize();

    logsHelper.d('Reinitialize the flutter BLE lib');

    _bleReInitCtrl.add(null);

    await _onBleReInit();
  }

  /// Called when the BLE status is updated
  void _onBleStatusUpdated(BleStatus status) {
    setEnabled(status == BleStatus.ready);
  }

  /// Called when the BLE is reinitialized to listen the status stream
  Future<void> _onBleReInit() async {
    await _bleStatusSub?.cancel();
    _bleStatusSub = _flutterBle.statusStream.listen(_onBleStatusUpdated);
    _onBleStatusUpdated(_flutterBle.status);
  }

  @override
  Future<void> dispose() async {
    final futuresList = <Future>[
      bleGapService.dispose(),
      bleGattService.dispose(),
      _bleReInitCtrl.close(),
    ];

    if (_bleStatusSub != null) {
      futuresList.add(_bleStatusSub!.cancel());
    }

    await Future.wait(futuresList);

    return super.dispose();
  }
}
