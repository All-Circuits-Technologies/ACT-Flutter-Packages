import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_appauth/flutter_appauth.dart' show AuthorizationServiceConfiguration;

class ProviderUrlConf extends Equatable {
  static const _authorizationEndpointKey = "authorizationEndpoint";

  static const _tokenEndpointKey = "tokenEndpoint";

  static const _endSessionEndpointKey = "endSessionEndpoint";

  final String authorizationEndpoint;

  final String tokenEndpoint;

  final String? endSessionEndpoint;

  const ProviderUrlConf({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.endSessionEndpoint,
  });

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

  AuthorizationServiceConfiguration toServiceConf() => AuthorizationServiceConfiguration(
    authorizationEndpoint: authorizationEndpoint,
    tokenEndpoint: tokenEndpoint,
    endSessionEndpoint: endSessionEndpoint,
  );

  @override
  List<Object?> get props => [authorizationEndpoint, tokenEndpoint, endSessionEndpoint];
}
