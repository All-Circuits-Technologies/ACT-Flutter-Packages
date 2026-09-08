// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Base class for all the server models
mixin Entity {
  /// Transform the Entity to JSON
  Map<String, dynamic> toJson();

  /// Test if the entity is valid
  bool get isValid;

  /// Parse from json to fill Entity data
  void parseFromJson(Map<String, dynamic> json) {}
}
