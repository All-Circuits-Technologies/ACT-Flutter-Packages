// Copyright (c) 2020. BMS Circuits

import 'package:act_thingsboard/src/model/db_entity.dart';
import 'package:act_thingsboard/src/model/device_attributes.dart';
import 'package:act_thingsboard/src/model/entity_id.dart';

/// Database model of the device got from server
class Device extends DbEntity {
  static const String _nameKey = "name";
  static const String _typeKey = "type";
  static const String _labelKey = "label";

  EntityId tenantId;
  EntityId customerId;
  String name;
  // In future this attribute could be transformed to enum
  String type;
  String label;

  /// The [DeviceAttributes] linked to this device
  DeviceAttributes deviceAttributes;

  /// Default constructor
  Device({
    EntityId entityId,
    DateTime createdTime,
    this.tenantId,
    this.customerId,
    this.name,
    this.type,
    this.label,
  }) : super(
          entityId: entityId,
          createdTime: createdTime,
        );

  /// Default fromJson constructor (this allow to construct the object from a
  /// JSON)
  Device.fromJson(Map<String, dynamic> json) {
    parseFromJson(json);
  }

  /// Transform the object to JSON
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();

    json[DbEntity.tenantIdKey] = tenantId?.toJson();
    json[DbEntity.customerIdKey] = customerId?.toJson();
    json[_nameKey] = name;
    json[_labelKey] = label;
    json[_typeKey] = type;

    return json;
  }

  /// Test if the object is valid
  @override
  bool get isValid {
    return super.isValid &&
        (tenantId?.isValid ?? false) &&
        (customerId?.isValid ?? false) &&
        (name?.isNotEmpty ?? false);
  }

  /// Parse and fill the object from the json given
  @override
  void parseFromJson(Map<String, dynamic> json) {
    if (json[DbEntity.tenantIdKey] is Map<String, dynamic>) {
      tenantId =
          EntityId.fromJson(json[DbEntity.tenantIdKey] as Map<String, dynamic>);
    }

    if (json[DbEntity.customerIdKey] is Map<String, dynamic>) {
      customerId = EntityId.fromJson(
          json[DbEntity.customerIdKey] as Map<String, dynamic>);
    }

    if (json[_nameKey] is String) {
      name = json[_nameKey] as String;
    }

    if (json[_labelKey] is String) {
      label = json[_labelKey] as String;
    }

    if (json[_typeKey] is String) {
      type = json[_typeKey] as String;
    }

    super.parseFromJson(json);
  }
}
