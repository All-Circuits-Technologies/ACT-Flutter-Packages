// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_oauth2_core/src/models/provider_url_conf.dart';
import 'package:equatable/equatable.dart';

/// Contains the OAuth 2 configuration to use for a given provider
class DefaultOAuth2Conf extends Equatable {
  /// This is the client id key used to parse information from a JSON conf object
  static const _clientIdKey = "clientId";

  /// This is the discovery url key used to parse information from a JSON conf object
  static const _discoveryUrlKey = "discoveryUrl";

  /// This is the issuer key used to parse information from a JSON conf object
  static const _issuerKey = "issuer";

  /// This is the service conf key used to parse information from a JSON conf object
  static const _serviceConfKey = "serviceConfiguration";

  /// This is the scopes key used to parse information from a JSON conf object
  static const _scopesKey = "scopes";

  /// This is the app auth redirect scheme key used to parse information from a JSON conf object
  static const _appAuthRedirectSchemeKey = "appAuthRedirectScheme";

  /// This is the ephemeral session key used to parse information from a JSON conf object
  static const _ephemeralSessionKey = "ephemeralSession";

  /// This is the client id linked to the OAuth2 config.
  ///
  /// This is unique to each client provider.
  final String clientId;

  /// This is the issuer of the OAuth2 config.
  ///
  /// An `issuer` is a well known provider such as Apple, Google, etc. and it's used to get the
  /// known discovery url.
  ///
  /// If you set this value, [discoveryUrl] and [providerUrlConf] aren't needed
  final String? issuer;

  /// The discovery url would be the URL for the discovery endpoint exposed by your provider that
  /// will return a document containing information about the OAuth 2.0 endpoints among other
  /// things.
  ///
  /// If you set this value [issuer] and [providerUrlConf] aren't needed
  final String? discoveryUrl;

  /// This is the list of needed URL to interact with the provider. This can be user if the provider
  /// has no [discoveryUrl] or if the issuer isn't well known.
  ///
  /// If you set this value [issuer] and [discoveryUrl] aren't needed
  final ProviderUrlConf? providerUrlConf;

  /// This contains the list of scopes used by the application and necessary to get from the
  /// provider.
  final List<String> scopes;

  /// This is the redirect scheme to give to the provider to return to the application
  final String appAuthRedirectScheme;

  /// True to open the provider pages in a browser session which shares nothing with the browser
  /// of the device, on iOS and macOS; the other platforms don't know of it.
  ///
  /// The system then asks the user nothing before opening them, and the session of the provider
  /// doesn't outlive the sign in in the browser, where anyone holding the device would find it.
  /// The price is that no session of the browser is reused: the user types their credentials at
  /// each sign in. An application which wants the single sign on with the browser says false.
  final bool ephemeralSession;

  /// Class constructor
  const DefaultOAuth2Conf({
    required this.clientId,
    required this.issuer,
    required this.discoveryUrl,
    required this.providerUrlConf,
    required this.scopes,
    required this.appAuthRedirectScheme,
    this.ephemeralSession = true,
  });

  /// Try to parse the configuration from a [json] object.
  ///
  /// If not null, [defaultIssuer] is used to set a default issuer if [_issuerKey] isn't in the
  /// given [json].
  static DefaultOAuth2Conf? tryToParseFromJson(Map<String, dynamic> json, {String? defaultIssuer}) {
    final loggerManager = appLogger();
    final clientId = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _clientIdKey,
      logger: loggerManager,
    );

    final discoveryUrlResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _discoveryUrlKey,
      canBeUndefined: true,
      logger: loggerManager,
    );

    final issuerResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _issuerKey,
      canBeUndefined: true,
      logger: loggerManager,
    );

    final appAuthRedirectScheme = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _appAuthRedirectSchemeKey,
      logger: loggerManager,
    );

    final scopes = JsonUtility.getNotNullPrimaryElementsList<String>(
      json: json,
      key: _scopesKey,
      logger: loggerManager,
    );

    final ephemeralSessionResult = JsonUtility.getOnePrimaryElement<bool>(
      json: json,
      key: _ephemeralSessionKey,
      canBeUndefined: true,
      logger: loggerManager,
    );

    final serviceConfJson = JsonUtility.getJsonObject(
      json: json,
      key: _serviceConfKey,
      canBeUndefined: true,
      logger: loggerManager,
    );

    if (clientId == null ||
        !discoveryUrlResult.isOk ||
        !issuerResult.isOk ||
        !serviceConfJson.isOk ||
        !ephemeralSessionResult.isOk ||
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
      ephemeralSession: ephemeralSessionResult.value ?? true,
    );
  }

  /// Class properties
  @override
  List<Object?> get props => [
    clientId,
    issuer,
    discoveryUrl,
    providerUrlConf,
    scopes,
    appAuthRedirectScheme,
    ephemeralSession,
  ];
}
