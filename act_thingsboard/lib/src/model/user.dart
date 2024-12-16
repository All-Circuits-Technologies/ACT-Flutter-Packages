// Copyright (c) 2020. BMS Circuits

import 'package:act_thingsboard/src/model/db_entity.dart';
import 'package:act_thingsboard/src/model/entity_id.dart';

/// Database model of the user got from server
class User extends DbEntity {
  static const String _privacyPolicyAcceptedKey = "privacyPolicyAccepted";
  static const String _langKey = "lang";
  static const String _emailKey = "email";
  static const String _authorityKey = "authority";
  static const String _firstNameKey = "firstName";
  static const String _lastNameKey = "lastName";
  static const String _nameKey = "name";

  EntityId tenantId;
  EntityId customerId;
  bool privacyPolicyAccepted;
  String lang;
  String email;
  String authority;
  String firstName;
  String lastName;
  String name;

  /// Default constructor
  User({
    EntityId entityId,
    DateTime createdTime,
    this.tenantId,
    this.privacyPolicyAccepted,
    this.lang,
    this.customerId,
    this.email,
    this.authority,
    this.firstName,
    this.lastName,
    this.name,
  }) : super(
          entityId: entityId,
          createdTime: createdTime,
        );

  /// Default fromJson constructor (this allow to construct the object from a
  /// JSON)
  User.fromJson(Map<String, dynamic> json) {
    parseFromJson(json);
  }

  /// Transform the object to JSON
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = super.toJson();

    json[DbEntity.tenantIdKey] = tenantId?.toJson();
    json[DbEntity.additionalInfoKey] = {
      _privacyPolicyAcceptedKey: privacyPolicyAccepted,
      _langKey: lang,
    };
    json[DbEntity.customerIdKey] = customerId?.toJson();
    json[_emailKey] = email;
    json[_authorityKey] = authority;
    json[_firstNameKey] = firstName;
    json[_lastNameKey] = lastName;
    json[_nameKey] = name;

    return json;
  }

  /// Test if the object is valid
  @override
  bool get isValid {
    return super.isValid &&
        (tenantId?.isValid ?? false) &&
        (customerId?.isValid ?? false) &&
        (email?.isNotEmpty ?? false) &&
        (authority?.isNotEmpty ?? false) &&
        (firstName?.isNotEmpty ?? false) &&
        (lastName?.isNotEmpty ?? false) &&
        (name?.isNotEmpty ?? false);
  }

  /// Parse and fill the object from the json given
  @override
  void parseFromJson(Map<String, dynamic> json) {
    if (json[DbEntity.tenantIdKey] is Map<String, dynamic>) {
      tenantId =
          EntityId.fromJson(json[DbEntity.tenantIdKey] as Map<String, dynamic>);
    }

    var additionalInfo = json[DbEntity.additionalInfoKey];
    if (additionalInfo is Map<String, dynamic>) {
      if (additionalInfo[_privacyPolicyAcceptedKey] is bool) {
        privacyPolicyAccepted =
            additionalInfo[_privacyPolicyAcceptedKey] as bool;
      }

      if (additionalInfo[_langKey] is String) {
        lang = additionalInfo[_langKey] as String;
      }
    }

    if (json[DbEntity.customerIdKey] is Map<String, dynamic>) {
      customerId = EntityId.fromJson(
          json[DbEntity.customerIdKey] as Map<String, dynamic>);
    }

    if (json[_emailKey] is String) {
      email = json[_emailKey] as String;
    }

    if (json[_authorityKey] is String) {
      authority = json[_authorityKey] as String;
    }

    if (json[_firstNameKey] is String) {
      firstName = json[_firstNameKey] as String;
    }

    if (json[_lastNameKey] is String) {
      lastName = json[_lastNameKey] as String;
    }

    if (json[_nameKey] is String) {
      name = json[_nameKey] as String;
    }

    super.parseFromJson(json);
  }
}
