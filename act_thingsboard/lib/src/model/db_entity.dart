// Copyright (c) 2020. BMS Circuits

import 'package:act_entity/act_entity.dart';
import 'package:act_thingsboard/src/model/entity_id.dart';

/// Represents a database model got from server
abstract class DbEntity implements Entity {
  static const String _idKey = "id";
  static const String _createdTimeKey = "createdTime";

  static const String additionalInfoKey = "additionalInfo";
  static const String tenantIdKey = "tenantId";
  static const String customerIdKey = "customerId";

  /// The entity id
  EntityId _entityId;

  /// Entity id getter
  EntityId get entityId => _entityId;

  /// The UTC creation datetime of the entity in the database, in UTC
  DateTime createdTime;

  /// Default constructor
  DbEntity({EntityId entityId, this.createdTime})
      : _entityId = entityId,
        super();

  /// Default fromJson constructor (this allow to construct the object from a
  /// JSON)
  DbEntity.fromJson(Map<String, dynamic> json) : super() {
    parseFromJson(json);
  }

  /// Transform the object to JSON
  @override
  Map<String, dynamic> toJson() => {
        _idKey: _entityId?.toJson(),
        _createdTimeKey: createdTime?.millisecondsSinceEpoch,
      };

  /// Test if the object is valid
  @override
  bool get isValid {
    return (createdTime != null) && (_entityId?.isValid ?? false);
  }

  /// Parse and fill the object from the json given
  @override
  void parseFromJson(Map<String, dynamic> json) {
    if (json[_idKey] is Map<String, dynamic>) {
      _entityId = EntityId.fromJson(json[_idKey] as Map<String, dynamic>);
    }

    if (json[_createdTimeKey] is int) {
      createdTime = DateTime.fromMillisecondsSinceEpoch(
        json[_createdTimeKey] as int,
        isUtc: true,
      );
    }
  }
}
