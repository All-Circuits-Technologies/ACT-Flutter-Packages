// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_ble_manager/act_ble_manager.dart';
import 'package:act_ble_manager_ui/src/blocs/scanned_devices/ble_scanned_devices_event.dart';
import 'package:act_ble_manager_ui/src/blocs/scanned_devices/ble_scanned_devices_state.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mutex/mutex.dart';

/// This is the callback used to filter the received devices.
/// True if we want to display the device, false to not display it
typedef FilterDevice = bool Function(BleScannedDevice device);

/// This bloc is useful to display BLE scanned devices
///
/// In your view, you may emit the events:
/// - [StartBleScanEvent] to start the scan of devices (if the scan is already active, this does
///   nothing)
/// - [StopBleScanEvent] to stop the BLE scan
/// - [ClearScannedDevicesListEvent] to clear the BLE devices list (this doesn't stop scanning and
///   the list will be refilled with time). The scan manages the devices list cleaning by itself;
///   therefore, there is no need to call this method to remove no more detected devices.
/// - [RequestPermsAndServiceEnablingEvent] to request permissions and service enabling to the user
///
/// This bloc doesn't manage the redirection to a page in case of a device disconnection, if you
/// want to do that, see the mixin: [MixinRequiredBleDeviceConnection]
class BleScannedDevicesBloc extends Bloc<BleScannedDevicesEvent, BleScannedDevicesState> {
  /// This is the BLE scan handler
  final BleScanHandler _scanHandler;

  /// This is the subscription to scanned devices
  late final StreamSubscription _scannedDevicesSub;

  /// This is the subscription to bluetooth service enabling update
  late final StreamSubscription _bluetoothEnableSub;

  /// This is the mode to use for scanning
  final ScanMode scanMode;

  /// If not null, this is the filter to use to only display the wanted devices
  final FilterDevice? isDeviceHasToBeDisplayed;

  /// This mutex is used to prevent incoherent parallel calls
  final Mutex _manageDeviceMutex;

  /// If true, we consider that the BLE permissions and enabling acceptance are compulsory
  final bool isAcceptanceCompulsoryForPermRequest;

  /// Class constructor
  BleScannedDevicesBloc({
    this.scanMode = ScanMode.balanced,
    this.isDeviceHasToBeDisplayed,
    this.isAcceptanceCompulsoryForPermRequest = false,
  })  : _scanHandler = globalGetIt().get<BleManager>().bleGapService.toGenerateScanHandler(),
        _manageDeviceMutex = Mutex(),
        super(InitBleScannedDevicesState(
          isBluetoothActive: globalGetIt().get<BleManager>().isEnabled,
        )) {
    final bleManager = globalGetIt().get<BleManager>();
    _scannedDevicesSub = _scanHandler.scannedDevices.listen(_onScannedDevicesReceived);
    _bluetoothEnableSub = bleManager.enabledStream.listen(_onBluetoothEnableUpdated);
    on<StartBleScanEvent>(_onStartBleScanEvent);
    on<StopBleScanEvent>(_onStopBleScanEvent);
    on<ClearScannedDevicesListEvent>(_onClearScannedDevicesListEvent);
    on<BleScanUpdateStatusEvent>(_onBleScanUpdateStatusEvent);
    on<RequestPermsAndServiceEnablingEvent>(_onRequestPermsAndServiceEnablingEvent);
    on<BluetoothEnableStatusEvent>(_onBluetoothEnableStatusEvent);

    add(const RequestPermsAndServiceEnablingEvent());
  }

  /// Called when a [BleScanUpdateStatus] event is received
  void _onScannedDevicesReceived(BleScanUpdateStatus device) {
    add(BleScanUpdateStatusEvent(scanUpdateStatus: device));
  }

  /// Called when the [StartBleScanEvent] event is received
  ///
  /// It manages scan handler start scanning
  Future<void> _onStartBleScanEvent(
    StartBleScanEvent event,
    Emitter<BleScannedDevicesState> emitter,
  ) async {
    // Start scan
    final success = await _scanHandler.startScan(scanMode: scanMode);

    emitter.call(
      BleScanState(
        previousState: state,
        isScanActive: success,
      ),
    );
  }

  /// Called when the [StopBleScanEvent] event is received
  ///
  /// It manages scan handler stop scanning
  Future<void> _onStopBleScanEvent(
    StopBleScanEvent event,
    Emitter<BleScannedDevicesState> emitter,
  ) async {
    await _scanHandler.stopScan();

    emitter.call(
      BleScanState(
        previousState: state,
        isScanActive: false,
      ),
    );
  }

  /// Called when the [ClearScannedDevicesListEvent] event is received
  ///
  /// It manages cleaning of the devices list
  Future<void> _onClearScannedDevicesListEvent(
    ClearScannedDevicesListEvent event,
    Emitter<BleScannedDevicesState> emitter,
  ) =>
      _manageDeviceMutex.protect(() async {
        emitter(BleUpdateDevicesState(
          previousState: state,
          devices: const [],
        ));
      });

  /// Called when the [BleScanUpdateStatusEvent] event is received
  ///
  /// It manages the update of the devices list
  Future<void> _onBleScanUpdateStatusEvent(
    BleScanUpdateStatusEvent event,
    Emitter<BleScannedDevicesState> emitter,
  ) =>
      _manageDeviceMutex.protect(() async {
        List<BleScannedDevice>? newDeviceList;

        switch (event.scanUpdateStatus.type) {
          case BleScanUpdateType.addDevice:
          case BleScanUpdateType.updateDevice:
            newDeviceList = _onAddOrUpdateScannedDevice(event.scanUpdateStatus.device);
            break;
          case BleScanUpdateType.removeDevice:
            newDeviceList = _onRemoveScannedDevice(event.scanUpdateStatus.device);
            break;
        }

        if (newDeviceList == null) {
          // Nothing to do
          return;
        }

        emitter(BleUpdateDevicesState(
          previousState: state,
          devices: newDeviceList,
        ));
      });

  /// Return a new list to use with the added or updated device
  /// If no device is added to the list, the method returns null.
  List<BleScannedDevice>? _onAddOrUpdateScannedDevice(BleScannedDevice deviceToAdd) {
    if (isDeviceHasToBeDisplayed != null && !isDeviceHasToBeDisplayed!(deviceToAdd)) {
      // Nothing to do
      return null;
    }

    // This prevent to modify the devices list display in the view before the state is emitted
    // (in the case another state is emitted in this process)
    final devices = List<BleScannedDevice>.from(state.devices);

    // Return if device already in list
    for (final device in devices) {
      if (device.id == deviceToAdd.id) {
        // It's useless to go further and compare the name (to see if they are different), because
        // in that case, the object returned by the scan handlers is the same as the object stored
        // in the state. Therefore their properties will be identical
        return null;
      }
    }

    // Update [devices] list
    devices.add(deviceToAdd);
    return devices;
  }

  /// Return a new list to use with the removed device
  /// If no device is removed from the list, the method returns null.
  List<BleScannedDevice>? _onRemoveScannedDevice(BleScannedDevice deviceToRemove) {
    // This prevent to modify the devices list display in the view before the state is emitted
    // (in the case another state is emitted in this process)
    final devices = List<BleScannedDevice>.from(state.devices);

    for (var idx = (devices.length - 1); idx >= 0; --idx) {
      final device = devices.elementAt(idx);
      if (device.id == deviceToRemove.id) {
        // Because we don't add two devices with the same id, if we remove it here, we are sure
        // there aren't a second to find in the list
        devices.removeAt(idx);
        return devices;
      }
    }

    return null;
  }

  /// Called when the [RequestPermsAndServiceEnablingEvent] event is received
  ///
  /// It manages the asking of permissions to user. If the user has agreed, the scan will be
  /// started (if the scan is already started, this will be managed by the scan handler).
  Future<void> _onRequestPermsAndServiceEnablingEvent(
    RequestPermsAndServiceEnablingEvent event,
    Emitter<BleScannedDevicesState> emitter,
  ) async {
    final status = await globalGetIt().get<BleManager>().checkAndAskForPermissionsAndServices(
          isAcceptanceCompulsory: isAcceptanceCompulsoryForPermRequest,
        );

    if (isClosed) {
      // The bloc has been closed while we request for the permissions; we don't go further
      return;
    }

    if (!status) {
      // Nothing to change
      return;
    }

    // If the scan is already active, nothing will be done; therefore, it's fine to emit the event
    add(const StartBleScanEvent());
  }

  /// Called when the bluetooth service state is updated
  void _onBluetoothEnableUpdated(bool value) {
    if (value == state.isBluetoothActive) {
      // Nothing to do
      return;
    }

    add(BluetoothEnableStatusEvent(
      isBluetoothActive: value,
    ));
  }

  /// Called when the [BluetoothEnableStatusEvent] event is received
  ///
  /// It manages the update of the state
  Future<void> _onBluetoothEnableStatusEvent(
    BluetoothEnableStatusEvent event,
    Emitter<BleScannedDevicesState> emitter,
  ) async {
    emitter(BluetoothEnableNewState(
      previousState: state,
      isBluetoothActive: event.isBluetoothActive,
    ));
  }

  /// Call when the BLoC has be to be closed
  @override
  Future<void> close() async {
    await Future.wait([
      _scannedDevicesSub.cancel(),
      _bluetoothEnableSub.cancel(),
    ]);

    await _scanHandler.dispose();

    if (_manageDeviceMutex.isLocked) {
      await _manageDeviceMutex.acquire();
      _manageDeviceMutex.release();
    }

    await super.close();
  }
}
