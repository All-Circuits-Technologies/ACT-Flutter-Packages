// Copyright (c) 2020. BMS Circuits

import 'dart:async';
import 'dart:convert';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_server_request_manager/act_server_request_manager.dart';
import 'package:act_thingsboard/act_thingsboard.dart';
import 'package:act_thingsboard/src/authentication_manager.dart';
import 'package:act_thingsboard/src/http/http_request_maker.dart';
import 'package:act_thingsboard/src/model/attribute_name.dart';
import 'package:act_thingsboard/src/model/attribute_scope.dart';
import 'package:act_thingsboard/src/model/device.dart';
import 'package:act_thingsboard/src/model/device_attributes.dart';
import 'package:act_thingsboard/src/model/entity_id.dart';
import 'package:act_thingsboard/src/model/user.dart';
import 'package:act_thingsboard/src/model/web_socket_receive_message.dart';
import 'package:act_thingsboard/src/tb_global_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:tuple/tuple.dart';

/// Builder for creating the DeviceManager
class DeviceBuilder extends ManagerBuilder<DeviceManager> {
  final Type _tbPropertiesManagerDepends;

  /// Class constructor with the class construction
  DeviceBuilder({
    @required AbstractAttributeNameHelper attributesHelper,
    @required Type tbPropertiesManagerDependency,
  })  : assert(tbPropertiesManagerDependency != null),
        _tbPropertiesManagerDepends = tbPropertiesManagerDependency,
        super(() => DeviceManager(attributesHelper: attributesHelper));

  /// List of manager dependence
  @override
  Iterable<Type> dependsOn() => [LoggerManager, _tbPropertiesManagerDepends];
}

/// Manager which helps to manage devices.
///
/// The [DeviceManager] helps to get devices from server but also store a cache
/// of those devices. This cache is saved in the mobile App, when an error
/// occurred on the server, the manager returns the cache.
///
/// To modify the attributes of a device, call the method
/// [DeviceManager.setDeviceAttributes]
class DeviceManager extends AbstractManager {
  final AbstractAttributeNameHelper attributesHelper;

  List<Device> _devicesCache;

  StreamController<List<Device>> _devicesStreamCtrl =
      StreamController.broadcast();

  /// Stream linked to the cache device, when the device list has been modified
  /// this emits the new list
  Stream<List<Device>> get cacheDevicesStream => _devicesStreamCtrl.stream;

  /// Class constructor
  DeviceManager({
    @required this.attributesHelper,
  })  : assert(attributesHelper != null),
        super() {
    _devicesCache = [];
  }

  /// Init the manager
  @override
  Future<void> initManager() async {
    _devicesCache = await _loadFromMemory(attributesHelper: attributesHelper);
  }

  /// Get the devices list from server
  ///
  /// If a problem occurs and the list can't be returned from server, the method
  /// returns a Generic Error with the devices stored in cache
  Future<Tuple2<RequestResult, List<Device>>> getDevices() async {
    AuthenticationManager authManager =
        GlobalGetIt().get<AuthenticationManager>();

    Tuple2<RequestResult, User> userResult = await authManager.currentUser;

    if (userResult.item1 != RequestResult.Ok) {
      return Tuple2(userResult.item1, _devicesCache);
    }

    User currentUser = userResult.item2;

    if (currentUser == null || !currentUser.isValid) {
      return Tuple2(RequestResult.GenericError, _devicesCache);
    }

    Tuple2<RequestResult, List<Device>> result =
        await HttpRequestMaker.getDevicesLinkedToUser(currentUser);

    if (result.item1 != RequestResult.Ok) {
      return Tuple2(result.item1, _devicesCache);
    }

    await _setDevicesInCache(result.item2);

    return result;
  }

  /// Set the attributes linked to a specific device
  Future<RequestResult> setDeviceAttributes(
    Device device,
    Map<AttributeName, dynamic> newAttrValues,
  ) async {
    Map<String, dynamic> sharedAttributes =
        _formatAttrForRequest(newAttrValues, true);
    Map<String, dynamic> serverAttributes =
        _formatAttrForRequest(newAttrValues, false);

    var futures = <Future<RequestResult>>[];

    if (sharedAttributes.isNotEmpty) {
      futures.add(HttpRequestMaker.setDeviceAttributes(
        device.entityId,
        sharedAttributes,
        // We use one of the shared scope (to choose one or the other doesn't
        // change anything here)
        AttributeScope.sharedOneWay,
      ));
    }

    if (serverAttributes.isNotEmpty) {
      futures.add(HttpRequestMaker.setDeviceAttributes(
        device.entityId,
        serverAttributes,
        AttributeScope.serverReadWrite,
      ));
    }

    if (futures.isEmpty) {
      // There is nothing to do
      return RequestResult.Ok;
    }

    List<RequestResult> results = await Future.wait(futures);

    if (sharedAttributes.isEmpty ||
        serverAttributes.isEmpty ||
        results[0] != RequestResult.Ok) {
      return results[0];
    }

    // Return the results of the second request if only:
    // * two requests have been done, and
    // * the first request returns OK, if not, we choose the worse result and
    //   do not choose between two errors
    return results[1];
  }

  /// Update the [DeviceAttributes] linked to the [deviceId] given and save the
  /// diff in memory
  ///
  /// Use only this method with the web socket message
  Future<void> updateAttributesFromServer(
    EntityId deviceId,
    WebSocketReceiveMessage msgReceived,
  ) async {
    Device device = _findDeviceInCache(deviceId);

    if (device == null) {
      // The device is not managed anymore don't do anything
      return null;
    }

    if (device.deviceAttributes == null) {
      device.deviceAttributes = DeviceAttributes(
        deviceId: device.entityId,
        attributesHelper: attributesHelper,
      );
    }

    if (device.deviceAttributes.updateFromServer(msgReceived.data)) {
      // At least one attribute to keep in memory of one managed device has been
      // changed; therefore we store the new device list in memory
      return _saveInMemory(_devicesCache);
    }

    return null;
  }

  /// Load the devices cache from memory and returns the list
  ///
  /// The devices returned have few details, only those kept in memory
  static Future<List<Device>> _loadFromMemory({
    @required AbstractAttributeNameHelper attributesHelper,
  }) async {
    assert(attributesHelper != null);
    var propertyManager = TbGlobalManager.getPropertiesManager();

    String inMemory = await propertyManager.devicesList.load();

    if (inMemory == null) {
      // Nothing has been stored in memory for now
      return [];
    }

    var rawJson;

    try {
      rawJson = jsonDecode(inMemory);
    } catch (error) {
      AppLogger().w("An error occurred when parsing property from "
          "memory");
    }

    if (rawJson is! List<Map<String, dynamic>>) {
      return [];
    }

    List<Map<String, dynamic>> deviceJson =
        rawJson as List<Map<String, dynamic>>;

    List<Device> devices = [];

    deviceJson.forEach((element) {
      var deviceAttr = DeviceAttributes.fromJson(
        element,
        attributesHelper: attributesHelper,
      );

      if (!deviceAttr.isValid) {
        AppLogger().w("The element got from memory is not valid to be "
            "saved in memory: $element");
        return;
      }

      Device device = Device(entityId: deviceAttr.deviceId);
      device.deviceAttributes = deviceAttr;

      devices.add(device);
    });

    return devices;
  }

  /// Save the devices list given into memory
  static Future<void> _saveInMemory(List<Device> devices) async {
    var propertyManager = TbGlobalManager.getPropertiesManager();

    List<Map<String, dynamic>> jsonDevices = [];

    devices.forEach((element) {
      DeviceAttributes deviceAttr = element.deviceAttributes;

      if (deviceAttr == null || !deviceAttr.isValid) {
        AppLogger().w("The device ${element.entityId} is not valid to be "
            "saved in memory");
        return;
      }

      jsonDevices.add(deviceAttr.toJson());
    });

    return propertyManager.devicesList.store(jsonEncode(jsonDevices));
  }

  /// Set the devices in cache
  ///
  /// The method searches in the cache if the device was already in cache, if
  /// true, it will set the [DeviceAttributes] of the old [Device] to the new
  /// one.
  Future<void> _setDevicesInCache(List<Device> newDevices) async {
    bool sameList = (_devicesCache.length == newDevices.length);

    for (Device newDevice in newDevices) {
      Device oldDevice = _findDeviceInCache(newDevice.entityId);

      if (oldDevice == null) {
        sameList = false;
        newDevice.deviceAttributes = DeviceAttributes(
          deviceId: newDevice.entityId,
          attributesHelper: attributesHelper,
        );
      } else {
        newDevice.deviceAttributes = oldDevice.deviceAttributes;
      }
    }

    _devicesCache = newDevices;

    await _saveInMemory(_devicesCache);

    if (!sameList) {
      _devicesStreamCtrl.add(_devicesCache);
    }
  }

  /// Find a device in cache thanks to its device id
  ///
  /// Returns null if no device has been found
  Device _findDeviceInCache(EntityId deviceId) {
    for (Device device in _devicesCache) {
      if (device.entityId == deviceId) {
        return device;
      }
    }

    return null;
  }

  /// Format attributes values got from the app to json values which can be
  /// sent to server
  static Map<String, dynamic> _formatAttrForRequest(
    Map<AttributeName, dynamic> values,
    bool isSharedAttr,
  ) {
    Map<String, dynamic> attrs = {};

    values.forEach((AttributeName key, value) {
      AttributeScope scope = key.scope;

      if (isSharedAttr &&
          scope != AttributeScope.sharedTwoWays &&
          scope != AttributeScope.sharedOneWay) {
        return;
      }

      if (!isSharedAttr && scope != AttributeScope.serverReadWrite) {
        return;
      }

      String attrName = key.strKeyForServer;

      if (!TypeUtility.testValueType(key.type, value)) {
        AppLogger().w("The attribute: ${key.strBase}, hasn't the right "
            "type, expected: ${key.type}");
        return;
      }

      attrs[attrName] = value;
    });

    return attrs;
  }
}
