// Copyright (c) 2020. BMS Circuits

/// Base class for all the server models
mixin Entity {
  /// Transform the Entity to JSON
  Map<String, dynamic> toJson();

  /// Test if the entity is valid
  bool get isValid;

  /// Parse from json to fill Entity data
  void parseFromJson(Map<String, dynamic> json) {}
}
