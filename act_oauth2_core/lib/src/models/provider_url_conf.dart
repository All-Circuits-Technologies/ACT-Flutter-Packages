// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_appauth/flutter_appauth.dart' show AuthorizationServiceConfiguration;

/// Contains the list of needed URL to interact with an OAuth provider
class ProviderUrlConf extends Equatable {
  /// This is the authorization endpoint key used to parse information from a JSON conf object
  static const _authorizationEndpointKey = "authorizationEndpoint";

  /// This is the token endpoint key used to parse information from a JSON conf object
  static const _tokenEndpointKey = "tokenEndpoint";

  /// This is the end session endpoint key used to parse information from a JSON conf object
  static const _endSessionEndpointKey = "endSessionEndpoint";

  /// This is the authorization endpoint of the OAuth provider
  final String authorizationEndpoint;

  /// This is the token endpoint of the OAuth provider
  final String tokenEndpoint;

  /// This is the end session endpoint of the OAuth provider
  final String? endSessionEndpoint;

  /// Class constructor
  const ProviderUrlConf({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.endSessionEndpoint,
  });

  /// Try to parse the [ProviderUrlConf] from a [json] object
  ///
  /// Returns null if the parsing failed
  static ProviderUrlConf? tryToParseFromJson(Map<String, dynamic> json) {
    final loggerManager = appLogger();

    final authorizationEndpoint = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _authorizationEndpointKey,
      loggerManager: loggerManager,
    );

    final tokenEndpoint = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _tokenEndpointKey,
      loggerManager: loggerManager,
    );

    final endSessionEndpointResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _endSessionEndpointKey,
      canBeUndefined: true,
      loggerManager: loggerManager,
    );

    if (authorizationEndpoint == null || tokenEndpoint == null || !endSessionEndpointResult.isOk) {
      loggerManager.w("Can't parse the provider url conf, there is a problem in the given JSON");
      return null;
    }

    return ProviderUrlConf(
      authorizationEndpoint: authorizationEndpoint,
      tokenEndpoint: tokenEndpoint,
      endSessionEndpoint: endSessionEndpointResult.value,
    );
  }

  /// Transform the object to a [AuthorizationServiceConfiguration] object which can be used by
  /// the external library
  AuthorizationServiceConfiguration toServiceConf() => AuthorizationServiceConfiguration(
    authorizationEndpoint: authorizationEndpoint,
    tokenEndpoint: tokenEndpoint,
    endSessionEndpoint: endSessionEndpoint,
  );

  /// Class properties
  @override
  List<Object?> get props => [authorizationEndpoint, tokenEndpoint, endSessionEndpoint];
}
