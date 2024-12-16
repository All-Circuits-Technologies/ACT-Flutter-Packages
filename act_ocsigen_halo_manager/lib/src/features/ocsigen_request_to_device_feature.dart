// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_halo_abstract/act_halo_abstract.dart';
import 'package:act_halo_manager/act_halo_manager.dart';
import 'package:act_ocsigen_halo_manager/src/models/ocsigen_request_id.dart';
import 'package:act_ocsigen_halo_manager/src/models/ocsigen_wifi_complete_scan_result.dart';
import 'package:act_ocsigen_halo_manager/src/models/ocsigen_wifi_connect_result.dart';
import 'package:act_ocsigen_halo_manager/src/models/ocsigen_wifi_status_result.dart';

/// This is the feature for calling requests on OCSIGEN device
/// It contains predefined methods known by every part
class OcsigenRequestToDeviceFeature<MaterialType> extends HaloRequestToDeviceFeature<MaterialType> {
  /// Class constructor
  OcsigenRequestToDeviceFeature({
    required super.haloManagerConfig,
  });

  /// Claim a device for a particular user
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurs in the process
  Future<bool?> claimDevice({
    required MaterialType materialType,
    required String key,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.claimDevice);

    if (requestId == null) {
      return null;
    }

    final payload = HaloPayloadPacket();
    payload.addString(key);

    final packet = HaloRequestParamsPacket(
      requestId: requestId,
      nbValues: const [1],
      parameters: payload,
    );

    return callBooleanFunction(materialType: materialType, request: packet);
  }

  /// Scan the WiFi seen by the device and returns a SSID list
  /// Returns the list of the scanned WiFi SSID.
  /// Returns null if a problem occurs in the process
  Future<List<String>?> wiFiSsidScan({
    required MaterialType materialType,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.wiFiSsidScan);

    if (requestId == null) {
      return null;
    }

    final result = await callFunction(
      materialType: materialType,
      request: HaloRequestParamsPacket.voidParams(requestId: requestId),
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
  /// Returns null if a problem occurs in the process
  Future<List<OcsigenWiFiCompleteScanResult>?> wiFiCompleteScan({
    required MaterialType materialType,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.wiFiCompleteScan);

    if (requestId == null) {
      return null;
    }

    final result = await callFunction(
      materialType: materialType,
      request: HaloRequestParamsPacket.voidParams(requestId: requestId),
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
  /// Returns null if a problem occurs in the process
  Future<OcsigenWiFiConnectResult?> wiFiConnect({
    required MaterialType materialType,
    required String ssid,
    required String password,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.wiFiConnect);

    if (requestId == null) {
      return null;
    }

    final payload = HaloPayloadPacket();
    payload.addString(ssid);
    payload.addString(password);

    final packet = HaloRequestParamsPacket(
      requestId: requestId,
      nbValues: const [1, 1],
      parameters: payload,
    );

    final result = await callFunction(materialType: materialType, request: packet);

    if (result.error != HaloErrorType.noError) {
      appLogger().w("A problem occurred when calling the wifi connect function, can't proceed");
      return null;
    }

    return OcsigenWiFiConnectResult.parseFromDevice(result.result!);
  }

  /// Disconnect from the WiFi
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurs in the process
  Future<bool?> wiFiDisconnect({
    required MaterialType materialType,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.wiFiDisconnect);

    if (requestId == null) {
      return null;
    }

    return callBooleanFunction(
      materialType: materialType,
      request: HaloRequestParamsPacket.voidParams(requestId: requestId),
    );
  }

  /// Try to get the current WiFi status on the device
  /// Returns the WiFi status
  /// Returns null if a problem occurs in the process
  Future<List<OcsigenWiFiStatusResult>?> wiFiGetStatus({
    required MaterialType materialType,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.wiFiGetStatus);

    if (requestId == null) {
      return null;
    }

    final result = await callFunction(
      materialType: materialType,
      request: HaloRequestParamsPacket.voidParams(requestId: requestId),
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
  /// Returns null if a problem occurs in the process
  Future<String?> wiFiGetMacAddress({
    required MaterialType materialType,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.wiFiGetMacAddress);

    if (requestId == null) {
      return null;
    }

    return callStringFunction(
      materialType: materialType,
      request: HaloRequestParamsPacket.voidParams(requestId: requestId),
    );
  }

  /// Try to activate the WiFi access point
  /// Returns true if the request succeeds in the device or false if not in the device.
  /// Returns null if a problem occurs in the process
  Future<bool?> apWiFiEnable({
    required MaterialType materialType,
    bool enable = true,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.apWifiEnable);

    if (requestId == null) {
      return null;
    }

    final payload = HaloPayloadPacket();
    payload.addBoolean(enable);

    final packet = HaloRequestParamsPacket(
      requestId: requestId,
      nbValues: const [1],
      parameters: payload,
    );

    return callBooleanFunction(materialType: materialType, request: packet);
  }

  /// Ask for the device to echo the param sent
  /// Returns the value you ask to echo
  /// Returns null if a problem occurs in the process
  Future<int?> echo({
    required MaterialType materialType,
    required int uInt8ToRepeat,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.echo);

    if (requestId == null) {
      return null;
    }

    final payload = HaloPayloadPacket();
    if (!payload.addUInt8(uInt8ToRepeat)) {
      appLogger().w("The parameter given is not an uint8, we can't call the echo function");
      return null;
    }

    final packet = HaloRequestParamsPacket(
      requestId: requestId,
      nbValues: const [1],
      parameters: payload,
    );

    return callUIntFunction(materialType: materialType, request: packet);
  }

  /// Get the serial number of the device
  /// Returns the serial number of the device
  /// Returns null if a problem occurs in the process
  Future<String?> getSerialNumber({
    required MaterialType materialType,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.getSerialNumber);

    if (requestId == null) {
      return null;
    }

    return callStringFunction(
      materialType: materialType,
      request: HaloRequestParamsPacket.voidParams(requestId: requestId),
    );
  }

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
  /// Returns null if a problem occurs in the process
  Future<bool?> setGpsCoordinates({
    required MaterialType materialType,
    required double latitude,
    required double longitude,
    required int decimalPoint,
  }) async {
    final requestId = _getRequestId(OcsigenRequestId.setGpsCoordinates);

    if (requestId == null) {
      return null;
    }

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
      requestId: requestId,
      nbValues: const [1, 1, 1],
      parameters: payload,
    );

    return callBooleanFunction(materialType: materialType, request: packet);
  }

  /// Get the [HaloRequestId] from the [OcsigenRequestId] given.
  ///
  /// If this method returns null, it mean that you don't use [OcsigenRequestIdHelper] in your code.
  HaloRequestId? _getRequestId(OcsigenRequestId id) {
    final requestId = haloManagerConfig.requestIdHelper.requestIds[id.hexValue];

    if (requestId == null) {
      appLogger().w("The request id: $id isn't known by the HALO manager, can't proceed");
      return null;
    }

    return requestId;
  }
}
