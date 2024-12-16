// Copyright (c) 2020. BMS Circuits

import 'package:act_thingsboard/src/model/device.dart';
import 'package:act_thingsboard/src/model/entity_id.dart';
import 'package:act_thingsboard/src/model/entity_type.dart';
import 'package:act_thingsboard/src/tb_global_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:tuple/tuple.dart';

typedef int GenerateUniqueMsgId();

/// Defines the type of attributes to subscribe on
enum TypeOfSub { timeseries, history, attributes }

/// Message sent to web socket server in order to subscribe to attributes
/// modification
class WebSocketSendMessage {
  static const String _timeseriesSubCmdsKey = "tsSubCmds";
  static const String _historySubCmdsKey = "historyCmds";
  static const String _attributesSubCmdsKey = "attrSubCmds";
  static const String _cmdIdKey = "cmdId";

  Map<int, EntityId> _timeseriesSubCmds;
  Map<int, EntityId> _historySubCmds;
  Map<int, EntityId> _attributesSubCmds;

  /// Constructor to build the message to send to the web socket
  ///
  /// The [generateUniqueMsgId] function returns an unique id to use in the msg.
  /// The id is unique is the current web socket connection
  ///
  /// [timeseriesSubCmds], [historySubCmds] and [attributesSubCmds] are lists of
  /// devices to subscribe for getting the wanted objects.
  /// For example, to subscribe for device attributes update, add the device in
  /// the list [attributesSubCmds]
  WebSocketSendMessage({
    List<Device> timeseriesSubCmds,
    List<Device> historySubCmds,
    List<Device> attributesSubCmds,
    @required GenerateUniqueMsgId generateUniqueMsgId,
  }) : assert(generateUniqueMsgId != null) {
    _timeseriesSubCmds = _createMap(timeseriesSubCmds, generateUniqueMsgId);
    _historySubCmds = _createMap(historySubCmds, generateUniqueMsgId);
    _attributesSubCmds = _createMap(attributesSubCmds, generateUniqueMsgId);
  }

  /// This method allows to get an unique id for each device
  static Map<int, EntityId> _createMap(
    List<Device> devices,
    GenerateUniqueMsgId generateUniqueMsgId,
  ) {
    if (devices == null) {
      return {};
    }

    Map<int, EntityId> subCmds = {};

    devices.forEach((device) {
      subCmds[generateUniqueMsgId()] = device.entityId;
    });

    return subCmds;
  }

  /// Format to Json the device list with unique id
  static List<dynamic> _toJsonSubCmds(Map<int, EntityId> subCmds) {
    List<dynamic> list = [];

    subCmds.forEach((int key, EntityId entityId) {
      if (!entityId.isValid) {
        AppLogger().w("Can't subscribe to device not known by server");
        return;
      }

      list.add({
        _cmdIdKey: key,
        EntityId.entityTypeKey: entityId.entityType.upStr,
        EntityId.entityIdKey: entityId.id,
      });
    });

    return list;
  }

  /// Convert the object to Json, it's formatted like that:
  ///
  /// {
  ///     "tsSubCmds": [
  ///         {
  ///             "cmdId": 3,
  ///             "entityType": "DEVICE",
  ///             "entityId": "f37994b0-49ae-11ea-87f7-672f6e90d128"
  ///         }
  ///     ],
  ///     "historyCmds": [],
  ///     "attrSubCmds": [
  ///         {
  ///             "cmdId": 4,
  ///             "entityType": "DEVICE",
  ///             "entityId": "f37994b0-49ae-11ea-87f7-672f6e90d128"
  ///         }
  ///     ]
  /// }
  Map<String, dynamic> toJson() => {
        _timeseriesSubCmdsKey: _toJsonSubCmds(_timeseriesSubCmds),
        _historySubCmdsKey: _toJsonSubCmds(_historySubCmds),
        _attributesSubCmdsKey: _toJsonSubCmds(_attributesSubCmds),
      };

  /// Get the [EntityId] of the [Device], linked to [cmdId] given
  ///
  /// If the [cmdId] is unknown by the message, returns null
  Tuple2<TypeOfSub, EntityId> getDeviceId(int cmdId) {
    if (_attributesSubCmds.containsKey(cmdId)) {
      return Tuple2(TypeOfSub.attributes, _attributesSubCmds[cmdId]);
    }

    if (_historySubCmds.containsKey(cmdId)) {
      return Tuple2(TypeOfSub.history, _historySubCmds[cmdId]);
    }

    if (_timeseriesSubCmds.containsKey(cmdId)) {
      return Tuple2(TypeOfSub.timeseries, _timeseriesSubCmds[cmdId]);
    }

    return null;
  }

  /// The method test if we have subscribe to the attributes of the [device]
  /// given
  bool isDeviceSubForAttr(Device device) {
    for (EntityId deviceId in _attributesSubCmds.values) {
      if (deviceId == device.entityId) {
        return true;
      }
    }

    return false;
  }
}
