// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/act_halo_manager.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';

/// This is the feature for calling requests on OCSIGEN device
/// It contains predefined methods known by every part
class OcsigenRequestToDeviceFeature<HardwareType> extends HaloRequestToDeviceFeature<HardwareType> {
  /// Class constructor
  OcsigenRequestToDeviceFeature({
    required super.haloManagerConfig,
  });

  /// Claim a device for a particular user
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurred in the process
  Future<bool?> claimDevice({
    required HardwareType hardwareType,
    required String key,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    payload.addString(key);

    final packet = HaloRequestParamsPacket(
      requestId: OcsigenRequestId.claimDevice,
      nbValues: const [1],
      parameters: payload,
    );

    return callBooleanFunction(
      hardwareType: hardwareType,
      request: packet,
      executionTimeout: executionTimeout,
    );
  }

  /// Scan the WiFi seen by the device and returns a SSID list
  /// Returns the list of the scanned WiFi SSID.
  /// Returns null if a problem occurred in the process
  Future<List<String>?> wiFiSsidScan({
    required HardwareType hardwareType,
    Duration? executionTimeout,
  }) async {
    final result = await callFunction(
      hardwareType: hardwareType,
      request: HaloRequestParamsPacket.voidParams(
        requestId: OcsigenRequestId.wiFiSsidScan,
      ),
      executionTimeout: executionTimeout,
    );

    if (result.error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when calling the wifi ssid scan function, can't proceed");
      return null;
    }

    final resultPacket = result.result!;

    final value = resultPacket.getListString(0);

    if (value == null) {
      appLogger().w("The claim device returned value isn't a string list");
      return null;
    }

    return value.$1;
  }

  /// Scan the WiFi seen by the device and returns complete scan result
  /// Returns the list of the scanned WiFi.
  /// Returns null if a problem occurred in the process
  Future<List<OcsigenWiFiCompleteScanResult>?> wiFiCompleteScan({
    required HardwareType hardwareType,
    Duration? executionTimeout,
  }) async {
    final result = await callFunction(
      hardwareType: hardwareType,
      request: HaloRequestParamsPacket.voidParams(
        requestId: OcsigenRequestId.wiFiCompleteScan,
      ),
      executionTimeout: executionTimeout,
    );

    if (result.error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when calling the wifi complete scan function, can't "
          "proceed");
      return null;
    }

    return OcsigenWiFiCompleteScanResult.parseFromDevice(result.result!);
  }

  /// Try to connect to the WiFi thanks to the ids given
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurred in the process
  Future<OcsigenWiFiConnectResult?> wiFiConnect({
    required HardwareType hardwareType,
    required String ssid,
    required String password,
    OcsigenWiFiAuthMode authMode = OcsigenWiFiAuthMode.wiFiAuthAuto,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    payload.addString(ssid);
    payload.addString(password);
    payload.addUInt8(authMode.rawValue);

    final packet = HaloRequestParamsPacket(
      requestId: OcsigenRequestId.wiFiConnect,
      nbValues: const [1, 1, 1],
      parameters: payload,
    );

    final result = await callFunction(
      hardwareType: hardwareType,
      request: packet,
      executionTimeout: executionTimeout,
    );

    if (result.error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when calling the wifi connect function, can't proceed");
      return null;
    }

    return OcsigenWiFiConnectResult.parseFromDevice(result.result!);
  }

  /// Disconnect from the WiFi
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurred in the process
  Future<bool?> wiFiDisconnect({
    required HardwareType hardwareType,
    Duration? executionTimeout,
  }) async =>
      callBooleanFunction(
        hardwareType: hardwareType,
        request: HaloRequestParamsPacket.voidParams(
          requestId: OcsigenRequestId.wiFiDisconnect,
        ),
        executionTimeout: executionTimeout,
      );

  /// Try to get the current WiFi status on the device
  /// Returns the WiFi status
  /// Returns null if a problem occurred in the process
  Future<List<OcsigenWiFiStatusResult>?> wiFiGetStatus({
    required HardwareType materialType,
    Duration? executionTimeout,
  }) async {
    final result = await callFunction(
      hardwareType: materialType,
      request: HaloRequestParamsPacket.voidParams(
        requestId: OcsigenRequestId.wiFiGetStatus,
      ),
      executionTimeout: executionTimeout,
    );

    if (result.error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when calling the wifi get status function, can't "
          "proceed");
      return null;
    }

    return OcsigenWiFiStatusResult.parseFromDevice(result.result!);
  }

  /// Get the MAC address linked to the device WiFi module
  /// Returns the mac address linked to the WiFi module.
  /// Returns null if a problem occurred in the process
  Future<String?> wiFiGetMacAddress({
    required HardwareType hardwareType,
    Duration? executionTimeout,
  }) async =>
      callStringFunction(
        hardwareType: hardwareType,
        request: HaloRequestParamsPacket.voidParams(
          requestId: OcsigenRequestId.wiFiGetMacAddress,
        ),
        executionTimeout: executionTimeout,
      );

  /// Try to activate the WiFi access point
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurred in the process
  Future<bool?> apWiFiEnable({
    required HardwareType hardwareType,
    bool enable = true,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    payload.addBoolean(enable);

    final packet = HaloRequestParamsPacket(
      requestId: OcsigenRequestId.apWifiEnable,
      nbValues: const [1],
      parameters: payload,
    );

    return callBooleanFunction(
      hardwareType: hardwareType,
      request: packet,
      executionTimeout: executionTimeout,
    );
  }

  /// Ask for the device to echo the param sent
  /// Returns the value you ask to echo
  /// Returns null if a problem occurred in the process
  Future<int?> echo({
    required HardwareType hardwareType,
    required int uInt8ToRepeat,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    if (!payload.addUInt8(uInt8ToRepeat)) {
      appLogger().w("The parameter given is not an uint8, we can't call the echo function");
      return null;
    }

    final packet = HaloRequestParamsPacket(
      requestId: OcsigenRequestId.echo,
      nbValues: const [1],
      parameters: payload,
    );

    return callUIntFunction(
      hardwareType: hardwareType,
      request: packet,
      executionTimeout: executionTimeout,
    );
  }

  /// Get the serial number of the device
  /// Returns the serial number of the device
  /// Returns null if a problem occurred in the process
  Future<String?> getSerialNumber({
    required HardwareType hardwareType,
    Duration? executionTimeout,
  }) async =>
      callStringFunction(
        hardwareType: hardwareType,
        request: HaloRequestParamsPacket.voidParams(
          requestId: OcsigenRequestId.getSerialNumber,
        ),
        executionTimeout: executionTimeout,
      );

  /// Set the GPS coordinates to the device
  ///
  /// The value [decimalPoint] allows to convert the [latitude] and [longitude] to integer. We
  /// multiply the double values with the coefficient: 10 * [decimalPoint], in order to send some
  /// decimal values via the integer.
  ///
  /// For instance, if you want to send the [latitude] : 20.123456789, with a number of digits after
  /// comma equals to 5 (via the parameter [decimalPoint]), the method will send the value: 2012345.
  ///
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurred in the process
  Future<bool?> setGpsCoordinates({
    required HardwareType hardwareType,
    required double latitude,
    required double longitude,
    required int decimalPoint,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    if (!payload.addDoubleViaInt32(latitude, decimalPoint)) {
      appLogger().w("We can't add the latitude value to the payload packet");
      return null;
    }

    if (!payload.addDoubleViaInt32(longitude, decimalPoint)) {
      appLogger().w("We can't add the longitude value to the payload packet");
      return null;
    }

    if (!payload.addUInt8(decimalPoint)) {
      appLogger().w("We can't add the decimal point value to the payload packet");
      return null;
    }

    final packet = HaloRequestParamsPacket(
      requestId: OcsigenRequestId.setGpsCoordinates,
      nbValues: const [1, 1, 1],
      parameters: payload,
    );

    return callBooleanFunction(
      hardwareType: hardwareType,
      request: packet,
      executionTimeout: executionTimeout,
    );
  }

  /// Get the SSIDs of the WiFi saved in the device
  /// Returns the list of the saved WiFi SSID.
  /// Returns null if a problem occurred in the process
  Future<List<String>?> getSavedWiFi({
    required HardwareType hardwareType,
    Duration? executionTimeout,
  }) async {
    final result = await callFunction(
      hardwareType: hardwareType,
      request: HaloRequestParamsPacket.voidParams(
        requestId: OcsigenRequestId.getSavedWiFi,
      ),
      executionTimeout: executionTimeout,
    );

    if (result.error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when calling the get saved WiFi function, can't proceed");
      return null;
    }

    final resultPacket = result.result!;

    final value = resultPacket.getListString(0);

    if (value == null) {
      appLogger().w("The saved WiFi returned value isn't a string list");
      return null;
    }

    return value.$1;
  }

  /// Forget the saved WiFi SSID
  ///
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurred in the process
  Future<bool?> forgetSavedWiFi({
    required HardwareType hardwareType,
    required String wiFiSsid,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    payload.addString(wiFiSsid);

    final packet = HaloRequestParamsPacket(
      requestId: OcsigenRequestId.forgetSavedWiFi,
      nbValues: const [1],
      parameters: payload,
    );

    return callBooleanFunction(
      hardwareType: hardwareType,
      request: packet,
      executionTimeout: executionTimeout,
    );
  }

  /// Inform the device we want to quit the communication and give to it the status of the
  /// communication end.
  ///
  /// The value of [endComStatus] can be dependent of the project; that's why its type is
  /// [MixinHaloType]. But some elements are reserved and can be seen through the enum:
  /// [RestrictedEndComStatus].
  /// In your project, you can use your own enum but you have to know that the raw values of the
  /// restricted statuses will be interpreted by the devices on already defined ways.
  ///
  /// Returns false if a problem occurred in the process
  Future<bool> quitCommunication({
    required HardwareType hardwareType,
    required MixinHaloType endComStatus,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    payload.addUInt8(endComStatus.rawValue);

    final packet = HaloRequestParamsPacket(
      requestId: OcsigenRequestId.quitCommunication,
      nbValues: const [1],
      parameters: payload,
    );

    final result = await callProcedure(
      hardwareType: hardwareType,
      request: packet,
      executionTimeout: executionTimeout,
    );

    if (result != HaloErrorType.noError) {
      appLogger().w("A problem occurred when calling the QUIT Communication procedure, can't "
          "proceed");
      return false;
    }

    return true;
  }
}
