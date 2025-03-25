// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_ble_manager/src/ble_manager.dart';
import 'package:act_ble_manager/src/data/error_messages.dart' as error_messages;
import 'package:act_ble_manager/src/data/scan_constants.dart' as ble_scan_constants;
import 'package:act_ble_manager/src/models/ble_scan_update_status.dart';
import 'package:act_ble_manager/src/models/ble_scanned_device.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:mutex/mutex.dart';

/// Manages all the scan features of BLE (the GAP part)
class BleGapService extends AbsWithLifeCycle {
  /// The scan fails in timeout if we haven't received scan element in this duration
  /// This allows to restart the scan
  ///
  /// In Android, the scan stops silently after some times, this is needed to keep receiving
  /// information
  static const Duration scanTimeoutWithoutEvent = Duration(seconds: 30);

  /// The flutter BLE lib instance
  final FlutterReactiveBle _flutterBle;

  /// The BLE manager
  final BleManager _bleManager;

  /// Mutex used to manage concurrency inside BLE
  final Mutex _bleAccessMutex;

  /// Mutex used to manage the [_releaseOne] and [_takeOne], one at the time
  final Mutex _takeAndReleaseMutex;

  /// BLE Scan Handler number
  final Map<ScanMode, int> _handlers = {};

  /// Scanned devices map
  final Map<String, BleScannedDevice> _deviceMap = {};

  /// Stream subscription of the enabled ble state
  late final StreamSubscription<bool> _enabledSub;

  /// Stream subscription of the permissions ble state
  late final StreamSubscription<bool> _permissionsSub;

  /// Stream subscription of the lib re init
  late final StreamSubscription<void> _libReInitSub;

  /// Controller of scanned device stream
  final StreamController<BleScanUpdateStatus> _scannedDevices;

  /// Getter of scanned device stream
  Stream<BleScanUpdateStatus> get scannedDevices => _scannedDevices.stream;

  /// Timer used in scan loop
  Timer? _scanTimer;

  /// The current scan mode, if null, it means that there is no scan asked
  ScanMode? _currentScanMode;

  /// Say if the other services have asked for scanning
  bool get _isScanHasBeenAsked => _currentScanMode != null;

  /// This is the subscription to listen for discovered device
  // The StreamSubscription is cancel in the method _endScan and the method is called in the dispose
  // method; therefore, it's a false positive
  // ignore: cancel_subscriptions
  StreamSubscription<DiscoveredDevice>? _scanSub;

  /// True when we want to display in logs the BLE scanned devices
  bool displayScannedDeviceInLogs;

  /// This is a list of service advertising UUIDs used to filter the searched devices
  Set<Uuid> _deviceAdvServiceUuidToSearch;

  /// Getter of service advertising UUIDs for filtering devices
  Set<Uuid> get deviceAdvServiceUuidToSearch => _deviceAdvServiceUuidToSearch;

  /// Ble manager constructor
  BleGapService({
    required FlutterReactiveBle flutterReactiveBle,
    required BleManager bleManager,
  })  : _flutterBle = flutterReactiveBle,
        _bleManager = bleManager,
        _bleAccessMutex = Mutex(),
        _takeAndReleaseMutex = Mutex(),
        _scannedDevices = StreamController<BleScanUpdateStatus>.broadcast(),
        displayScannedDeviceInLogs = false,
        _deviceAdvServiceUuidToSearch = {},
        super() {
    _enabledSub = _bleManager.enabledStream.listen(_onBleServiceAndPermissionsEnabled);
    _permissionsSub = _bleManager.permissionsStream.listen(_onBleServiceAndPermissionsEnabled);
    _libReInitSub = _bleManager.libReInitStream.listen(_onLibReInit);
  }

  /// Allow to generate a scan handler useful to manage multiple scanning
  ///
  /// Important ! Don't forget to call the dispose method of the
  /// [BleScanHandler] when you do no more need to use the instance
  BleScanHandler toGenerateScanHandler() => BleScanHandler._(this);

  /// Set advertising service UUIDs for filtering devices
  Future<void> setDeviceAdvServiceUuidsToSearch(Set<Uuid> uuids) async {
    if (setEquals(_deviceAdvServiceUuidToSearch, uuids)) {
      return;
    }

    _deviceAdvServiceUuidToSearch = uuids;

    if (_isScanHasBeenAsked) {
      await _restartScan();
    }
  }

  /// To call each time we want to start a scan
  /// There is multiple scan modes and each uses different level of battery, so
  /// the method applies the most critical scan mode asked
  Future<bool> _takeOne(ScanMode scanMode) async => _takeAndReleaseMutex.protect(() async {
        if (!_handlers.containsKey(scanMode)) {
          _handlers[scanMode] = 0;
        }

        _handlers[scanMode] = _handlers[scanMode]! + 1;

        // Get the highest scan mode in all the wanted modes
        final highest = _getHighestScanMode();

        final previousScanMode = _currentScanMode;

        if (_currentScanMode != null &&
            convertScanModeToArgs(_currentScanMode!) >= convertScanModeToArgs(highest!)) {
          // Nothing to do because we run the app at its highest asked level
          // Current scan mode can be null (the first time) but not highest because
          // we add a +1 just before
          // Current scan mode is only null when no scan is running
          return true;
        }

        _currentScanMode = highest;

        final result = await _restartScan();

        if (!result) {
          // Failed to launch scan
          _handlers[scanMode] = _handlers[scanMode]! - 1;
          _currentScanMode = previousScanMode;
          return false;
        }

        return true;
      });

  /// This method is called each time an element do not more need scanning.
  /// The method will test all the scan mode previously asked and reduce the
  /// consumption, or stop the scan (if no more scan has been asked)
  Future<void> _releaseOne(ScanMode scanMode) async => _takeAndReleaseMutex.protect(() async {
        // If we release it means that we takeOne at least once with this scanMode
        _handlers[scanMode] = _handlers[scanMode]! - 1;

        final highest = _getHighestScanMode();

        if (highest == null) {
          // If highest is null, it means that there is no more scan to do
          await _stopScan();
          _currentScanMode = null;
          return;
        }

        // CurrentScanMode can't be null here
        if (convertScanModeToArgs(highest) == convertScanModeToArgs(_currentScanMode!)) {
          // That means that there is nothing to do
          return;
        }

        // If we are here it means that we have to modify the scanmode
        _currentScanMode = highest;

        await _restartScan();
      });

  /// Stop and start the scan
  Future<bool> _restartScan() async {
    await _stopScan();
    return _startScan();
  }

  /// Start BLE scan loop and periodic scan action
  ///
  /// This method calls [_launchScan]
  Future<bool> _startScan() async {
    if (!_isScanHasBeenAsked) {
      _bleManager.logsHelper.w("We try to start the scan, but it's not wanted");
      return false;
    }

    if (!await _bleManager.checkAndAskForPermissionsAndServices()) {
      // This test manage the case where the user haven't accepted the BLE
      // permissions or if the BLE service isn't enabled
      _bleManager.logsHelper.w("The user don't have accepted the BLE permission or the BLE "
          "service isn't enabled; therefore we can't start the scan");
      return false;
    }

    if (!(await _launchScan())) {
      return false;
    }

    await _checkScannedDevicesPeriodic();

    return true;
  }

  /// Stop BLE scan loop
  Future<void> _stopScan() async {
    if (!_isScanHasBeenAsked) {
      // Nothing to do
      return;
    }

    _scanTimer?.cancel();

    await _endScan();
    _deviceMap.clear();
  }

  /// Periodic scan actions
  Future<void> _checkScannedDevicesPeriodic() async {
    if (_isScanHasBeenAsked) {
      await _updateScannedDeviceList();

      _scanTimer = Timer(
        ble_scan_constants.scanOnDuration,
        _checkScannedDevicesPeriodic,
      );
    }
  }

  /// Update scanned list and remove device that have not advertise since a
  /// `time ble_scan_constants` (from [ble_scan_constants]) in seconds
  Future<void> _updateScannedDeviceList() async {
    final devicesToRemove = <BleScannedDevice>[];
    for (final discoveredDevice in _deviceMap.values) {
      final seconds = DateTime.now().toUtc().difference(discoveredDevice.lastSeenTs).inSeconds;
      if (seconds > ble_scan_constants.scanMaxTimeDeviceDisappeared.inSeconds) {
        devicesToRemove.add(discoveredDevice);
      }
    }

    for (final toRemove in devicesToRemove) {
      await _removeDevice(toRemove);
    }
  }

  /// Launch scan BLE
  ///
  /// The method is called by [_startScan]
  ///
  /// Returns false, if we don't have the permission to scan for Ble devices
  Future<bool> _launchScan() async {
    var result = true;

    try {
      /* TODO(brolandeau): Normally, to gain time when scanning, we have to give some services of
                           the device to filter them, but this isn't working for now
       */
      _scanSub = _flutterBle
          .scanForDevices(
            withServices: _deviceAdvServiceUuidToSearch.toList(growable: false),
            scanMode: _currentScanMode!,
          )
          .timeout(
            scanTimeoutWithoutEvent,
            onTimeout: _onScanTimeout,
          )
          .listen(
            _addScanDeviceCallback,
            onError: _onScanError,
          );
    } catch (error) {
      result = false;
      _bleManager.logsHelper.w('An exception occurred when scanning devices: $error');
    }

    return result;
  }

  /// Stop scan BLE
  Future<void> _endScan() async {
    if (_scanSub != null) {
      final scanSub = _scanSub;
      _scanSub = null;
      await scanSub?.cancel();
    }
  }

  /// Add scan device to device list and send event on stream
  Future<void> _addScanDeviceCallback(DiscoveredDevice discoveredDevice) async =>
      _bleAccessMutex.protect(() async {
        String? keyFound;

        // Check if device is already in list

        if (_deviceMap.containsKey(discoveredDevice.id)) {
          keyFound = discoveredDevice.id;
        }

        if (displayScannedDeviceInLogs && discoveredDevice.name.isNotEmpty) {
          _bleManager.logsHelper.d('Device discovered, id: ${discoveredDevice.id}, '
              'name: ${discoveredDevice.name}');
        }

        if (keyFound != null) {
          // If device is already in list, update it and send an update event
          final scannedDevice = _deviceMap[keyFound]!;

          scannedDevice.updateFromDiscoveredDevice(discoveredDevice);
          _scannedDevices.add(
            BleScanUpdateStatus(
              BleScanUpdateType.updateDevice,
              scannedDevice,
            ),
          );
        } else if (discoveredDevice.id.isNotEmpty) {
          // If device is new, add it to the list and send an add event
          final scannedDevice = BleScannedDevice(discoveredDevice);

          _deviceMap[discoveredDevice.id] = scannedDevice;
          _scannedDevices.add(
            BleScanUpdateStatus(
              BleScanUpdateType.addDevice,
              scannedDevice,
            ),
          );
        }
      });

  /// Remove device from device list and send event on stream
  Future<void> _removeDevice(BleScannedDevice device) async => _bleAccessMutex.protect(() async {
        _deviceMap.remove(device.id);
        _scannedDevices.add(
          BleScanUpdateStatus(
            BleScanUpdateType.removeDevice,
            device,
          ),
        );
      });

  /// Returns the current highest scan mode (the one using the most energy)
  ScanMode? _getHighestScanMode() {
    ScanMode? highestScanMode;

    for (final scanMode in _handlers.keys) {
      if (_handlers[scanMode] == 0) {
        continue;
      }

      highestScanMode ??= ScanMode.opportunistic;

      if (convertScanModeToArgs(scanMode) > convertScanModeToArgs(highestScanMode)) {
        highestScanMode = scanMode;
      }
    }

    return highestScanMode;
  }

  /// Called when an error occurred while scanning
  Future<void> _onScanError(Object error) async {
    _bleManager.logsHelper.e("An error occurred in the BLE scan process: $error");

    if (error is! Exception) {
      return;
    }

    if (_currentScanMode == null) {
      // Nothing to do
      return;
    }

    final stringError = error.toString();

    if (stringError.contains(error_messages.scanThrottle)) {
      _bleManager.logsHelper.e("The scan fails with an unknown error, we try to relaunch it with "
          "the scan timeout");
    }
  }

  /// This is called when the scan fails in timeout
  ///
  /// In Android, the scan stops silently after some times, this is needed to restart the scan and
  /// keep receiving information
  Future<void> _onScanTimeout([_]) async {
    if (_scanSub != null) {
      _bleManager.logsHelper.i("The scan has been ended but we don't want it, we restart the scan");
      await _restartScan();
    }
  }

  /// Called when the BLE enabling or the permissions status has changed
  Future<void> _onBleServiceAndPermissionsEnabled(_) async {
    final enabled = _bleManager.hasPermissions && _bleManager.isEnabled;

    if (enabled && _currentScanMode != null && _scanSub == null) {
      // In that case, we restore the BLE status, we relaunch the scan
      _bleManager.logsHelper.i("The ble is enabled and permissions are ok, we restart scanning");

      // We wait some times before restarting the connection after the ble is re-detected, this is
      // necessary or the lib crash silently
      await Future.delayed(ble_scan_constants.waitBeforeRestartingScan);

      await _restartScan();
    } else if (!enabled && _currentScanMode != null && _scanSub != null) {
      _bleManager.logsHelper.w("The ble has been disabled or the permissions are no more okay, we "
          "stop scanning");
      await _stopScan();
    }
  }

  /// Called when the BLE lib has been reinitialized
  Future<void> _onLibReInit([_]) async {
    if (_currentScanMode != null) {
      // If a scan was processing, we restart the scan
      _bleManager.logsHelper.d('Restart the scan after reinitialization');
      await _restartScan();
    }
  }

  /// Dispose method for the manager
  @override
  Future<void> disposeLifeCycle() async {
    final futuresList = <Future>[
      _scannedDevices.close(),
      _enabledSub.cancel(),
      _permissionsSub.cancel(),
      _endScan(),
      _libReInitSub.cancel(),
    ];

    if (_scanTimer?.isActive ?? false) {
      _scanTimer!.cancel();
    }

    if (_bleAccessMutex.isLocked) {
      await _bleAccessMutex.acquire();
      _bleAccessMutex.release();
    }

    if (_takeAndReleaseMutex.isLocked) {
      await _takeAndReleaseMutex.acquire();
      _takeAndReleaseMutex.release();
    }

    await Future.wait(futuresList);

    return super.disposeLifeCycle();
  }
}

/// BLE scan handler
class BleScanHandler {
  final BleGapService _bleGapService;
  final Mutex _bleAsking;

  ScanMode _scanModeAsked = ScanMode.balanced;

  /// Scan active
  bool _active;

  /// Say if we are scanning for devices
  bool get active => _active;

  /// Returns the scanned devices
  Stream<BleScanUpdateStatus> get scannedDevices => _bleGapService.scannedDevices;

  /// Ble manager constructor
  BleScanHandler._(BleGapService bleGapService)
      : _bleGapService = bleGapService,
        _bleAsking = Mutex(),
        _active = false;

  /// Start BLE scan loop and periodic scan action
  Future<bool> startScan({
    ScanMode scanMode = ScanMode.balanced,
  }) =>
      _bleAsking.protect(() async {
        if (_active) {
          // Already active
          return true;
        }

        _scanModeAsked = scanMode;

        _active = await _bleGapService._takeOne(scanMode);

        return active;
      });

  /// Stop BLE scan loop
  Future<void> stopScan() => _bleAsking.protect(() async {
        if (!_active) {
          return;
        }

        _active = false;
        await _bleGapService._releaseOne(_scanModeAsked);
      });

  /// Test if the device given is currently detected
  bool isDetected(String id) => _bleGapService._deviceMap.containsKey(id);

  /// Get the detected device from its [id]
  ///
  /// Returns null if the device isn't known
  BleScannedDevice? getDetectedDevice(String id) {
    if (!isDetected(id)) {
      // The device isn't detected
      return null;
    }

    return _bleGapService._deviceMap[id];
  }

  /// Dispose method of the Handler class
  Future<void> dispose() async => stopScan();
}
