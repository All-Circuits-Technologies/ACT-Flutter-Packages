// Copyright (c) 2020. BMS Circuits

/// Entity type
enum EntityType { user, device, tenant, customer }

/// Extension of the entity type
extension EntityTypeExtension on EntityType {
  /// Getter allows to get a string representation of the enum
  ///
  /// Good to know : the toString() method of enum will display the enum class
  /// name like this: HttpMethod.delete
  String get upStr => this.toString().split('.').last.toUpperCase();
}

/// Helper class for the entity type
class EntityTypeHelper {
  /// Parse the EntityType from [str] parameter
  static EntityType parseFromStr(String str) {
    String tmpStr = str.toUpperCase();

    for (EntityType entityType in EntityType.values) {
      if (entityType.upStr == tmpStr) {
        return entityType;
      }
    }

    return null;
  }
}
