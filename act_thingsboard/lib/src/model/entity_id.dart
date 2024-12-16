// Copyright (c) 2020. BMS Circuits

import 'package:act_entity/act_entity.dart';
import 'package:act_thingsboard/src/model/entity_type.dart';
import 'package:equatable/equatable.dart';

/// This represents the ID of database entity got from the server
class EntityId extends Equatable implements Entity {
  static const String entityTypeKey = 'entityType';
  static const String entityIdKey = 'entityId';
  static const String _idKey = 'id';

  final EntityType entityType;
  final String id;

  /// Default constructor
  EntityId({
    this.entityType,
    this.id,
  });

  /// Default fromJson constructor (this allow to construct the object from a
  /// JSON)
  factory EntityId.fromJson(Map<String, dynamic> json) {
    EntityType entityType;
    String id;

    if (json[entityTypeKey] is String) {
      String tmpEntityType = json[entityTypeKey] as String;
      entityType = EntityTypeHelper.parseFromStr(tmpEntityType);
    }

    if (json[_idKey] is String) {
      id = json[_idKey] as String;
    }

    return EntityId(
      entityType: entityType,
      id: id,
    );
  }

  /// Transform the Entity to JSON
  @override
  Map<String, dynamic> toJson() =>
      {entityTypeKey: entityType.upStr, _idKey: id};

  /// Test if the entity is valid
  @override
  bool get isValid {
    return (entityType != null && id != null && id.isNotEmpty);
  }

  @override
  List<Object> get props => [entityType, id];

  /// Do nothing here, because the class is immutable
  @override
  void parseFromJson(Map<String, dynamic> json) {}
}
