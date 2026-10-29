// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/act_halo_manager.dart';
import 'package:act_ocsigen_halo_manager/act_ocsigen_halo_manager.dart';

/// This is the feature for calling requests on OCSIGEN device
/// It contains predefined methods known by every part
class OcsigenRequestToDeviceFeature<HardwareType> extends HaloRequestToDeviceFeature<HardwareType> {
  /// This is the default authentication mode for the WiFi connection
  static const defaultAuthMode = OcsigenWiFiAuthMode.wiFiAuthAuto;

  /// Class constructor
  OcsigenRequestToDeviceFeature({
    required super.haloManagerConfig,
  });

  /// Claim a device for a particular user
  ///
  /// The result value is true if the request succeeds in the device or false if not in the device.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, bool>> claimDevice({
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
  ///
  /// The result value is the list of the scanned WiFi SSID.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, List<String>>> wiFiSsidScan({
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

    if (result.isError) {
      appLogger().w("A problem occurred when calling the wifi ssid scan function, can't proceed");
      return ResultWithRequiredValue(status: result.status);
    }

    final resultPacket = result.value;

    if (resultPacket == null) {
      appLogger().w("The wifi ssid scan function hasn't returned a payload");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    final value = resultPacket.getListString(0);

    if (value.isError) {
      appLogger().w("The claim device returned value isn't a string list");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    return ResultWithRequiredValue(status: HaloErrorType.noError, value: value.value!.value);
  }

  /// Scan the WiFi seen by the device and returns complete scan result
  ///
  /// The result value is the list of the scanned WiFi.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, List<OcsigenWiFiCompleteScanResult>>>
      wiFiCompleteScan({
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

    if (result.isError) {
      appLogger().w("A problem occurred when calling the wifi complete scan function, can't "
          "proceed");
      return ResultWithRequiredValue(status: result.status);
    }

    final parsed = OcsigenWiFiCompleteScanResult.parseFromDevice(result.value!);

    if (parsed == null) {
      appLogger().w("The wifi complete scan returned value isn't well formatted");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    return ResultWithRequiredValue(status: HaloErrorType.noError, value: parsed);
  }

  /// Try to connect to the WiFi thanks to the ids given
  ///
  /// For supporting backwards compatibility on old boards, when [supportAuthMode] is equals to
  /// false and [authMode] is equals to the [defaultAuthMode], we don't add the parameters.
  ///
  /// The result value is the connection result sent by the device.
  /// If a problem occurred in the process (for instance when the auth mode isn't supported), the
  /// result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, OcsigenWiFiConnectResult>> wiFiConnect({
    required HardwareType hardwareType,
    required String ssid,
    required String password,
    OcsigenWiFiAuthMode authMode = defaultAuthMode,
    bool supportAuthMode = true,
    Duration? executionTimeout,
  }) async {
    if (authMode != defaultAuthMode && !supportAuthMode) {
      appLogger().w("We don't support the auth mode but the calling method has set an auth mode, "
          "different to the default mode: $defaultAuthMode");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    final payload = HaloPayloadPacket();
    payload.addString(ssid);
    payload.addString(password);
    if (supportAuthMode) {
      payload.addUInt8(authMode.rawValue);
    }

    final packet = HaloRequestParamsPacket(
      requestId: OcsigenRequestId.wiFiConnect,
      nbValues: [
        1,
        1,
        if (supportAuthMode) 1,
      ],
      parameters: payload,
    );

    final result = await callFunction(
      hardwareType: hardwareType,
      request: packet,
      executionTimeout: executionTimeout,
    );

    if (result.isError) {
      appLogger().w("A problem occurred when calling the wifi connect function, can't proceed");
      return ResultWithRequiredValue(status: result.status);
    }

    final parsed = OcsigenWiFiConnectResult.parseFromDevice(result.value!);

    if (parsed == null) {
      appLogger().w("The wifi connect returned value isn't well formatted");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    return ResultWithRequiredValue(status: HaloErrorType.noError, value: parsed);
  }

  /// Disconnect from the WiFi
  ///
  /// The result value is true if the request succeeds in the device or false if not in the device.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, bool>> wiFiDisconnect({
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
  ///
  /// The result value is the WiFi status.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, List<OcsigenWiFiStatusResult>>> wiFiGetStatus({
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

    if (result.isError) {
      appLogger().w("A problem occurred when calling the wifi get status function, can't "
          "proceed");
      return ResultWithRequiredValue(status: result.status);
    }

    final parsed = OcsigenWiFiStatusResult.parseFromDevice(result.value!);

    if (parsed == null) {
      appLogger().w("The wifi get status returned value isn't well formatted");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    return ResultWithRequiredValue(status: HaloErrorType.noError, value: parsed);
  }

  /// Get the MAC address linked to the device WiFi module
  ///
  /// The result value is the mac address linked to the WiFi module.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, String>> wiFiGetMacAddress({
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
  ///
  /// The result value is true if the request succeeds in the device or false if not in the device.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, bool>> apWiFiEnable({
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
  ///
  /// The result value is the value you ask to echo.
  /// If a problem occurred in the process (for instance when [uInt8ToRepeat] isn't an uint8), the
  /// result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, int>> echo({
    required HardwareType hardwareType,
    required int uInt8ToRepeat,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    if (!payload.addUInt8(uInt8ToRepeat)) {
      appLogger().w("The parameter given is not an uint8, we can't call the echo function");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
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
  ///
  /// The result value is the serial number of the device.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, String>> getSerialNumber({
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
  /// The result value is true if the request succeeds in the device or false if not in the device.
  /// If a problem occurred in the process (for instance when a value can't be added to the
  /// payload), the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, bool>> setGpsCoordinates({
    required HardwareType hardwareType,
    required double latitude,
    required double longitude,
    required int decimalPoint,
    Duration? executionTimeout,
  }) async {
    final payload = HaloPayloadPacket();
    if (!payload.addDoubleViaInt32(latitude, decimalPoint)) {
      appLogger().w("We can't add the latitude value to the payload packet");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    if (!payload.addDoubleViaInt32(longitude, decimalPoint)) {
      appLogger().w("We can't add the longitude value to the payload packet");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    if (!payload.addUInt8(decimalPoint)) {
      appLogger().w("We can't add the decimal point value to the payload packet");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
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
  ///
  /// The result value is the list of the saved WiFi SSID.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, List<String>>> getSavedWiFi({
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

    if (result.isError) {
      appLogger().w("A problem occurred when calling the get saved WiFi function, can't proceed");
      return ResultWithRequiredValue(status: result.status);
    }

    final resultPacket = result.value;

    if (resultPacket == null) {
      appLogger().w("The get saved WiFi function hasn't returned a payload");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    final value = resultPacket.getListString(0);

    if (value.isError) {
      appLogger().w("The saved WiFi returned value isn't a string list");
      return const ResultWithRequiredValue(status: HaloErrorType.formatError);
    }

    return ResultWithRequiredValue(status: HaloErrorType.noError, value: value.value!.value);
  }

  /// Forget the saved WiFi SSID
  ///
  /// The result value is true if the request succeeds in the device or false if not in the device.
  /// If a problem occurred in the process, the result status is the error.
  Future<ResultWithRequiredValue<HaloErrorType, bool>> forgetSavedWiFi({
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
  /// Returns the status of the procedure call: [HaloErrorType.noError] if everything went well,
  /// the error otherwise.
  Future<HaloErrorType> quitCommunication({
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

    if (result.isError) {
      appLogger().w("A problem occurred when calling the QUIT Communication procedure, can't "
          "proceed");
    }

    return result;
  }
}
