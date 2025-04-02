// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_device_values.dart';
import 'package:act_thingsboard_client/src/services/devices/values/tb_telemetry_handler.dart';
import 'package:act_thingsboard_client/src/services/tb_request_service.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This service manages the Thingsboard devices
class TbDevicesService extends AbsWithLifeCycle {
  /// The logs category linked to devices
  static const _tbLogsCategory = "devices";

  /// The default devices number to get by page
  static const _devicesNumberByPage = 50;

  /// The thingsboard request service
  final TbRequestService _requestService;

  /// The logs helper linked to the manager
  late final LogsHelper _logsHelper;

  /// The device values linked to the known devices
  final Map<String, TbDeviceValues> _deviceValues;

  /// Class constructor
  TbDevicesService({
    required TbRequestService requestService,
    required LogsHelper logsHelper,
  })  : _requestService = requestService,
        _deviceValues = {},
        _logsHelper = logsHelper.createASubLogsHelper(_tbLogsCategory);

  /// The method creates and returns a [TbTelemetryHandler] linked to the [deviceId] given
  TbTelemetryHandler createTelemetryHandler(String deviceId) {
    var deviceValues = _deviceValues[deviceId];

    if (deviceValues == null) {
      deviceValues = TbDeviceValues(
        requestService: _requestService,
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
    final authUser = await _requestService.getSafeAuthUser();

    if (authUser == null) {
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

    final result = await _requestService
        .safeRequest((tbClient) async => tbClient.getDeviceService().getCustomerDevices(
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
      final result = await _requestService
          .safeRequest((tbClient) async => tbClient.getDeviceService().getCustomerDeviceInfos(
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

  /// Dispose the service
  @override
  Future<void> disposeLifeCycle() async {
    for (final watcher in _deviceValues.values) {
      await watcher.dispose();
    }

    await super.disposeLifeCycle();
  }
}
