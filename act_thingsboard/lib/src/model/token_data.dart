// Copyright (c) 2020. BMS Circuits

import 'package:act_entity/act_entity.dart';

/// Token used by the HTTP server
class TokenData implements Entity {
  static const String _tokenKey = 'token';
  static const String _refreshToken = 'refreshToken';

  String token;
  String refreshToken;

  /// [TokenData] constructor
  TokenData(
    this.token,
    this.refreshToken,
  );

  /// [TokenData] constructor with empty valued
  TokenData.init()
      : token = "",
        refreshToken = "";

  /// Default fromJson constructor (this allow to construct an entity from a
  /// JSON)
  TokenData.fromJson(Map<String, dynamic> json) {
    parseFromJson(json);
  }

  /// [TokenData] constructor from [json]
  @override
  void parseFromJson(Map<String, dynamic> json) {
    if (json[_tokenKey] is String) {
      token = json[_tokenKey] as String;
    }

    if (json[_refreshToken] is String) {
      refreshToken = json[_refreshToken] as String;
    }
  }

  /// Transform the Entity to JSON
  @override
  Map<String, dynamic> toJson() => {
        _tokenKey: token,
        _refreshToken: refreshToken,
      };

  /// Return if token is valid
  @override
  bool get isValid {
    return (token != "" && refreshToken != "");
  }

  /// Clear the token data and make it invalid
  void clear() {
    token = "";
    refreshToken = "";
  }
}
