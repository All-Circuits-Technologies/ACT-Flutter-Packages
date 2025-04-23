import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_core/src/models/provider_url_conf.dart';
import 'package:equatable/equatable.dart';

class DefaultOAuth2Conf extends Equatable {
  static const _clientIdKey = "clientId";

  static const _discoveryUrlKey = "discoveryUrl";

  static const _issuerKey = "issuer";

  static const _serviceConfKey = "serviceConfiguration";

  static const _scopesKey = "scopes";

  static const _appAuthRedirectSchemeKey = "appAuthRedirectScheme";

  final String clientId;

  final String? issuer;

  final String? discoveryUrl;

  final ProviderUrlConf? providerUrlConf;

  final List<String> scopes;

  final String appAuthRedirectScheme;

  const DefaultOAuth2Conf({
    required this.clientId,
    required this.issuer,
    required this.discoveryUrl,
    required this.providerUrlConf,
    required this.scopes,
    required this.appAuthRedirectScheme,
  });

  static DefaultOAuth2Conf? tryToParseFromJson(Map<String, dynamic> json, {String? defaultIssuer}) {
    final loggerManager = appLogger();
    final clientId = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _clientIdKey,
      loggerManager: loggerManager,
    );

    final discoveryUrlResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _discoveryUrlKey,
      canBeUndefined: true,
      loggerManager: loggerManager,
    );

    final issuerResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _issuerKey,
      canBeUndefined: true,
      loggerManager: loggerManager,
    );

    final appAuthRedirectScheme = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _appAuthRedirectSchemeKey,
      loggerManager: loggerManager,
    );

    final scopes = JsonUtility.getNotNullPrimaryElementsList<String>(
      json: json,
      key: _scopesKey,
      loggerManager: loggerManager,
    );

    final serviceConfJson = JsonUtility.getJsonObject(
      json: json,
      key: _serviceConfKey,
      canBeUndefined: true,
      loggerManager: loggerManager,
    );

    if (clientId == null ||
        !discoveryUrlResult.isOk ||
        !issuerResult.isOk ||
        !serviceConfJson.isOk ||
        scopes == null ||
        appAuthRedirectScheme == null) {
      loggerManager.w("Can't parse the default oauth2 conf, there is a problem in the given JSON");
      return null;
    }

    ProviderUrlConf? providerUrlConf;
    if (serviceConfJson.value != null) {
      providerUrlConf = ProviderUrlConf.tryToParseFromJson(serviceConfJson.value!);
      if (providerUrlConf == null) {
        loggerManager.w("The provider url conf can't be parsed form key: $_serviceConfKey");
        return null;
      }
    }

    if (discoveryUrlResult.value == null &&
        issuerResult.value == null &&
        providerUrlConf == null &&
        defaultIssuer == null) {
      loggerManager.w("No information linked to the OpenID URLs has been given");
      return null;
    }

    return DefaultOAuth2Conf(
      clientId: clientId,
      discoveryUrl: discoveryUrlResult.value,
      issuer: issuerResult.value ?? defaultIssuer,
      providerUrlConf: providerUrlConf,
      scopes: scopes,
      appAuthRedirectScheme: appAuthRedirectScheme,
    );
  }

  @override
  List<Object?> get props => [
    clientId,
    issuer,
    discoveryUrl,
    providerUrlConf,
    scopes,
    appAuthRedirectScheme,
  ];
}
