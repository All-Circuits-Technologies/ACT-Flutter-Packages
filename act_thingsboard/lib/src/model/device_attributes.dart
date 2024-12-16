// Copyright (c) 2020. BMS Circuits

import 'dart:async';
import 'dart:convert';

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_entity/act_entity.dart';
import 'package:act_thingsboard/src/model/attribute_name.dart';
import 'package:act_thingsboard/src/model/entity_id.dart';
import 'package:act_thingsboard/src/model/entity_type.dart';
import 'package:act_thingsboard/src/model/web_socket_receive_message.dart';
import 'package:act_thingsboard/src/tb_global_manager.dart';
import 'package:flutter/foundation.dart';

/// This class is linked to a device and contains the device attributes
class DeviceAttributes implements Entity {
  final AbstractAttributeNameHelper attributesHelper;

  /// The entity id of the device linked to those attributes
  EntityId deviceId;

  /// The attributes values
  Map<AttributeName, String> _attributesValues = {};

  StreamController<List<AttributeName>> _attrStreamCtrl =
      StreamController.broadcast();

  /// The stream sends a message each time attributes have been changed on
  /// server.
  ///
  /// The message sent is the list of the attributes modified
  Stream<List<AttributeName>> get attributesStream => _attrStreamCtrl.stream;

  /// Class constructor
  DeviceAttributes({
    @required this.attributesHelper,
    this.deviceId,
    Map<AttributeName, String> attributes = const {},
  })  : assert(attributesHelper != null),
        super() {
    _attributesValues.addAll(attributes);
  }

  /// Allows to construct a class instance with a given json
  DeviceAttributes.fromJson(
    Map<String, dynamic> json, {
    @required this.attributesHelper,
  })  : assert(attributesHelper != null),
        super() {
    parseFromJson(json);
  }

  /// Parse and create a device attributes from a json object
  @override
  void parseFromJson(Map<String, dynamic> json) {
    if (json[EntityId.entityIdKey] is String) {
      deviceId = EntityId(
        entityType: EntityType.device,
        id: json[EntityId.entityIdKey] as String,
      );
    }

    Map<AttributeName, String> attributes;

    for (AttributeName attrName
        in attributesHelper.getAttributesStoredInMemory()) {
      if (json[attrName] == null) {
        continue;
      }

      attributes[attrName] = json[attrName].toString();
    }
  }

  /// Transform the class to json
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> jsonMemory = {
      EntityId.entityIdKey: deviceId.id,
    };

    for (AttributeName attrName
        in attributesHelper.getAttributesStoredInMemory()) {
      jsonMemory[attrName.strBase] = _attributesValues[attrName];
    }

    return jsonMemory;
  }

  /// Test if the class is valid
  @override
  bool get isValid {
    return deviceId.isValid;
  }

  /// Get a string representation of the attribute value
  String getStrAttrValue(AttributeName attrName) {
    return _attributesValues[attrName];
  }

  /// Get the parsed attribute value
  ///
  /// You can get an integer, a String, a boolean and a DateTime (from an UNIX
  /// timestamp in seconds)
  T getAttrValue<T>(AttributeName attrName) {
    String value = _attributesValues[attrName];

    if (value == null) {
      return null;
    }

    if (T == int) {
      return int.tryParse(value) as T;
    }

    if (T == bool) {
      return BoolHelper.tryParse(value) as T;
    }

    if (T == DateTime) {
      int ts = int.tryParse(value);

      if (ts == null || ts < 0) {
        AppLogger().w("Can't parse the value: $value of attribute: "
            "${attrName.strBase}, to DateTime");
        return null;
      }

      return DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true) as T;
    }

    return value as T;
  }

  /// Get the parsed attribute value
  ///
  /// You can get a model extended from Entity
  /// You have to give an instance of your class [entity] which will be filled and returned.
  T getAttrValueFromEntity<T extends Entity>(AttributeName attrName, T entity) {
    Map<String, dynamic> json;
    String value = _attributesValues[attrName];

    if (value == null) {
      return null;
    }

    try {
      json = jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      AppLogger().w("Can't parsed to JSON : $value");
    }

    if (json == null) {
      return null;
    }

    entity.parseFromJson(json);

    return entity;
  }

  /// Called by [DeviceManager] when a new message is received by the web socket
  ///
  /// Don't call this method, if you want to set the value of an attribute, use
  /// the method [DeviceManager.setDeviceAttributes]
  bool updateFromServer(Map<String, WsAttribute> attributes) {
    List<AttributeName> attributesModified = [];

    bool toSaveInMemory = false;
    List<AttributeName> savedInMemory =
        attributesHelper.getAttributesStoredInMemory();

    attributes.forEach((key, value) {
      AttributeName attrName = attributesHelper.parseFromServer(key);

      if (attrName == null) {
        // Unknown key or not usable here, therefore do nothing
        return;
      }

      String strValue = attributes[key].latestValue;

      if (strValue != null) {
        _attributesValues[attrName] = strValue;
        attributesModified.add(attrName);

        if (strValue != _attributesValues[attrName] &&
            savedInMemory.contains(attrName)) {
          toSaveInMemory = true;
        }
      }
    });

    if (attributesModified.isNotEmpty) {
      _attrStreamCtrl.add(attributesModified);
    }

    return toSaveInMemory;
  }
}
