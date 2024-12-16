// Copyright (c) 2020. BMS Circuits

import 'package:act_entity/act_entity.dart';

/// Database model of the user got from server
class UserSignUpData implements Entity {
  static const String _emailKey = "email";
  static const String _firstNameKey = "firstName";
  static const String _lastNameKey = "lastName";
  static const String _passwordKey = "password";
  static const String _reCaptchaKey = "recaptchaResponse";

  String email;
  String _password;
  String _reCaptcha;
  String firstName;
  String lastName;

  /// Default constructor
  UserSignUpData(
    String email,
    String password,
    String reCaptcha, {
    String firstName,
    String lastName,
  })  : email = email,
        _password = password,
        _reCaptcha = reCaptcha,
        firstName = firstName,
        lastName = lastName;

  /// Transform the object to JSON
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = Map<String, dynamic>();

    json[_emailKey] = email;
    if (firstName != null) {
      json[_firstNameKey] = firstName;
    }

    if (lastName != null) {
      json[_lastNameKey] = lastName;
    }

    json[_passwordKey] = _password;
    json[_reCaptchaKey] = _reCaptcha;
    _password = "";

    return json;
  }

  /// Test if the object is valid
  @override
  bool get isValid {
    return (email?.isNotEmpty ?? false) &&
        (_password?.isNotEmpty ?? false) &&
        (_reCaptcha?.isNotEmpty ?? false);
  }

  /// Parse and fill the object from the json given
  @override
  void parseFromJson(Map<String, dynamic> json) {
    if (json[_emailKey] is String) {
      email = json[_emailKey] as String;
    }

    if (json[_firstNameKey] is String) {
      firstName = json[_firstNameKey] as String;
    }

    if (json[_lastNameKey] is String) {
      lastName = json[_lastNameKey] as String;
    }

    if (json[_reCaptchaKey] is String) {
      _reCaptcha = json[_reCaptchaKey] as String;
    }

    if (json[_passwordKey] is String) {
      _password = json[_passwordKey] as String;
    }
  }
}
