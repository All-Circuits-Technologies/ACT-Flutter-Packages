// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_thingsboard_client/src/managers/abs_tb_server_req_manager.dart';
import 'package:act_thingsboard_client/src/models/tb_claim_attempt.dart';
import 'package:act_thingsboard_client/src/models/tb_request_response.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_device_values.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_telemetry_handler.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This service manages the Thingsboard devices
class TbDevicesService extends AbsWithLifeCycle {
  /// The logs category linked to devices
  static const _tbLogsCategory = "devices";

  /// The default devices number to get by page
  static const _devicesNumberByPage = 50;

  /// The Thingsboard statuses which have to keep throwing, so that the request manager sees a
  /// session problem, refreshes the token and tries the request once more
  static const _sessionHttpStatuses = [401, 403];

  /// The thingsboard request service
  final AbsTbServerReqManager _requestManager;

  /// The logs helper linked to the manager
  late final LogsHelper _logsHelper;

  /// The device values linked to the known devices
  final Map<String, TbDeviceValues> _deviceValues;

  /// Class constructor
  TbDevicesService({
    required AbsTbServerReqManager requestManager,
    required LogsHelper logsHelper,
  })  : _requestManager = requestManager,
        _deviceValues = {},
        _logsHelper = logsHelper.createSubLogger(subCategory: _tbLogsCategory);

  /// The method creates and returns a [TbTelemetryHandler] linked to the [deviceId] given
  TbTelemetryHandler createTelemetryHandler(String deviceId) {
    var deviceValues = _deviceValues[deviceId];

    if (deviceValues == null) {
      deviceValues = TbDeviceValues(
        requestManager: _requestManager,
        deviceId: deviceId,
        logsHelper: _logsHelper,
      );
      _deviceValues[deviceId] = deviceValues;
    }

    return deviceValues.createTelemetryHandler();
  }

  /// Get the customer id of the current user. This can only work if the current user is linked to
  /// a customer and not a tenant.
  ///
  /// Returns null if a problem occurred.
  Future<String?> getCurrentCustomerId() async {
    final authUserResult =
        await _requestManager.request((tbClient) async => tbClient.getAuthUser());
    final authUser = authUserResult.requestResponse;

    if (!authUserResult.isOk || authUser == null) {
      _logsHelper.w("We aren't logged, we can't get the customer id");
      return null;
    }

    final customerId = authUser.customerId;

    if (customerId == null) {
      _logsHelper.w("We aren't logged with a customer user account; therefore we can't get its "
          "customer id");
      return null;
    }

    return customerId;
  }

  /// Get the devices linked to the current user, the user has to be a customer user
  ///
  /// Returns null if a problem occurred.
  Future<PageData<Device>?> getCurrentCustomerDevices({
    PageLink? pageLink,
  }) async {
    final customerId = await getCurrentCustomerId();

    if (customerId == null) {
      _logsHelper.w("There is a problem with user customer id; we can't get the current customer "
          "devices");
      return null;
    }

    final result = await _requestManager
        .request((tbClient) async => tbClient.getDeviceService().getCustomerDevices(
              customerId,
              pageLink ?? PageLink(_devicesNumberByPage),
            ));

    if (!result.isOk) {
      _logsHelper.w("A problem occurred when tried to request the customer devices from the "
          "server");
      return null;
    }

    return result.requestResponse;
  }

  /// Get the devices of the current user, with the information the server adds to them, the user
  /// has to be a customer user.
  ///
  /// A [DeviceInfo] carries what a [Device] does not: whether the device is active, the title of
  /// the customer it belongs to and the name of its profile.
  ///
  /// Returns null if a problem occurred.
  Future<PageData<DeviceInfo>?> getCurrentCustomerDeviceInfos({
    PageLink? pageLink,
  }) async {
    final customerId = await getCurrentCustomerId();

    if (customerId == null) {
      _logsHelper.w("There is a problem with user customer id; we can't get the current customer "
          "device infos");
      return null;
    }

    final result = await _requestManager
        .request((tbClient) async => tbClient.getDeviceService().getCustomerDeviceInfos(
              customerId,
              pageLink ?? PageLink(_devicesNumberByPage),
            ));

    if (!result.isOk) {
      _logsHelper.w("A problem occurred when tried to request the customer device infos from the "
          "server");
      return null;
    }

    return result.requestResponse;
  }

  /// Get a device by its name, the device has to be attached to the customer of the current user.
  ///
  /// The current user has to be linked to a customer.
  ///
  /// The first returned element is equal to false, if a problem occurred in the process. The
  /// second element is the device retrieved.
  /// You can get the result: (true, null), in the case where the device is unknown for the current
  /// user
  Future<({bool success, DeviceInfo? deviceInfo})> getCustomerDeviceByName({
    required String deviceName,
  }) async {
    final customerId = await getCurrentCustomerId();

    if (customerId == null) {
      _logsHelper.w("There is a problem with user customer id; we can't get the device by name");
      return const (success: false, deviceInfo: null);
    }

    var pageLink = PageLink(_devicesNumberByPage, 0, deviceName);
    DeviceInfo? deviceFound;
    var hasNext = true;

    while (deviceFound == null && hasNext) {
      final result = await _requestManager
          .request((tbClient) async => tbClient.getDeviceService().getCustomerDeviceInfos(
                customerId,
                pageLink,
              ));

      final pageData = result.requestResponse;

      if (!result.isOk || pageData == null) {
        _logsHelper.w("A problem occurred when tried to request the customer devices from the "
            "server");
        return const (success: false, deviceInfo: null);
      }

      for (final device in pageData.data) {
        if (device.name == deviceName) {
          deviceFound = device;
        }
      }

      hasNext = pageData.hasNext;

      if (hasNext) {
        pageLink = PageLink(_devicesNumberByPage, pageLink.page + 1, deviceName);
      }
    }

    return (success: true, deviceInfo: deviceFound);
  }

  /// Delete every time series value the device [deviceId] holds, all keys, all times.
  ///
  /// The keys are read first because Thingsboard deletes by key only. A device which holds no time
  /// series is already purged: the method answers true without asking for any deletion.
  ///
  /// Returns false if a problem occurred.
  Future<bool> purgeDeviceTimeseries({required String deviceId}) async {
    final entityId = DeviceId(deviceId);

    final keysResult = await _requestManager
        .request((tbClient) async => tbClient.getAttributeService().getTimeseriesKeys(entityId));
    final keys = keysResult.requestResponse;

    if (!keysResult.isOk || keys == null) {
      _logsHelper.w("A problem occurred when tried to request the time series keys of the device "
          "$deviceId from the server; we can't purge them");
      return false;
    }

    if (keys.isEmpty) {
      return true;
    }

    final deleteResult = await _requestManager.request(
      (tbClient) async => tbClient.getAttributeService().deleteEntityTimeseries(
        entityId,
        keys,
        deleteAllDataForKeys: true,
        startTs: 0,
        endTs: 0,
        rewriteLatestIfDeleted: false,
      ),
    );

    if (!deleteResult.isOk || !(deleteResult.requestResponse ?? false)) {
      _logsHelper.w("A problem occurred when tried to delete the time series of the device "
          "$deviceId on the server");
      return false;
    }

    return true;
  }

  /// Ask Thingsboard to bind the device named [deviceName] to the customer of the current user,
  /// with the [secretKey] the device is waiting for.
  ///
  /// The endpoint is called directly rather than through `DeviceService.claimDevice` because the
  /// packaged `ClaimResult` parser reads `json['device']` unconditionally, and Thingsboard omits
  /// that field precisely on the answers worth telling apart (`CLAIMED`, `FAILURE`).
  ///
  /// The answer is handed over as it is, and [TbClaimAttempt.outcome] says what it amounts to.
  Future<TbClaimAttempt> claimDevice({
    required String deviceName,
    required String secretKey,
  }) async {
    int? httpStatus;
    String? deviceId;

    final response = await _requestManager.request<ClaimResponse?>((tbClient) async {
      // Deliberately untyped: Thingsboard answers this endpoint with an object on a successful
      // claim, but with a bare JSON string — "CLAIMED", "FAILURE" — on the refusals. Asking Dio
      // for a Map makes the refusals throw a cast error instead of being read, which is exactly
      // the case worth telling the user about.
      final answer = await tbClient.post<dynamic>(
        _claimPath(deviceName),
        // `secretKey` is always sent, and never null: Thingsboard dereferences it without checking
        // and answers a 500 when it is missing (thingsboard/thingsboard#3031).
        data: {"secretKey": secretKey},
        // Accept the refusal statuses so their body can be read; a session error still throws, and
        // so does anything from 500 up.
        options: Options(
          validateStatus: (status) =>
              status != null && status < 500 && !_sessionHttpStatuses.contains(status),
        ),
      );

      httpStatus = answer.statusCode;
      deviceId = parseDeviceId(answer.data);

      return parseClaimResponse(answer.data);
    });

    if (!response.isOk) {
      _logsHelper.w("A problem occurred when tried to claim the device '$deviceName'");
    }

    return TbClaimAttempt(
      status: response.status,
      httpStatus: httpStatus,
      response: response.requestResponse,
      deviceId: deviceId,
    );
  }

  /// Ask Thingsboard to unbind the device named [deviceName] from the customer holding it.
  ///
  /// Thingsboard lets any customer of the tenant release any device: `reClaimDevice` checks
  /// `CLAIM_DEVICES`, and its permission table grants that operation without ever looking at who
  /// owns the device.
  ///
  /// Once the broker of the stack releases the devices itself, an application has no reason left
  /// to call this one; it stays for the stacks which have no such broker.
  Future<TbRequestResponse<void>> releaseClaim({required String deviceName}) async {
    final response = await _requestManager.request<void>((tbClient) async {
      await tbClient.delete<void>(_claimPath(deviceName));
    });

    if (!response.isOk) {
      _logsHelper.w("A problem occurred when tried to release the claim of the device "
          "'$deviceName'");
    }

    return response;
  }

  /// Read the device [deviceId] back as the current user, which is the post-condition of a claim.
  ///
  /// A customer can only read a device which is assigned to them, so a device which comes back is
  /// the proof the binding landed; anything else — not found, refused, unreachable — is answered
  /// as not visible.
  Future<bool> isDeviceVisibleToCustomer(String deviceId) async {
    final response = await _requestManager.request<Device?>(
      (tbClient) async => tbClient.getDeviceService().getDevice(deviceId),
    );

    return response.isOk && response.requestResponse != null;
  }

  /// Read the id of the device Thingsboard says it bound, from the claim answer [body].
  ///
  /// Returns null when the answer carries no device, which is what every refusal looks like.
  @visibleForTesting
  static String? parseDeviceId(Object? body) {
    if (body is! Map<String, dynamic>) {
      return null;
    }

    final device = body["device"];

    if (device is! Map<String, dynamic>) {
      return null;
    }

    final id = device["id"];

    if (id is! Map<String, dynamic>) {
      return null;
    }

    final rawId = id["id"];

    return rawId is String && rawId.isNotEmpty ? rawId : null;
  }

  /// Read the claim answer Thingsboard sent in [body].
  ///
  /// Returns null when the body carries no claim answer at all, which is what the caller uses to
  /// fall back on the HTTP status.
  @visibleForTesting
  static ClaimResponse? parseClaimResponse(Object? body) {
    // Either the `response` field of an answer which is an object, or the whole body when
    // Thingsboard answers with a bare string.
    final raw = body is Map<String, dynamic> ? body["response"] : body;

    if (raw is! String) {
      return null;
    }

    for (final response in ClaimResponse.values) {
      if (response.name.toUpperCase() == raw.toUpperCase()) {
        return response;
      }
    }

    // An answer this version of Thingsboard does not know about
    return null;
  }

  /// The endpoint of the claim of the device named [deviceName]
  static String _claimPath(String deviceName) =>
      "/api/customer/device/${Uri.encodeComponent(deviceName)}/claim";

  /// Dispose the service
  @override
  Future<void> disposeLifeCycle() async {
    for (final watcher in _deviceValues.values) {
      await watcher.dispose();
    }

    await super.disposeLifeCycle();
  }
}
