// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The configuration of a provider which is known from its discovery document.
const _json = <String, dynamic>{
  "clientId": "aClient",
  "discoveryUrl": "https://a.provider/.well-known/openid-configuration",
  "scopes": ["openid", "profile"],
  "appAuthRedirectScheme": "com.example.app",
};

/// The configuration of [_json], without the key [without] and with what [and] adds to it.
Map<String, dynamic> _confWithout(String without, {Map<String, dynamic> and = const {}}) =>
    Map<String, dynamic>.from(_json)
      ..remove(without)
      ..addAll(and);

void main() {
  setUp(FakeGlobalManager.install);

  group("DefaultOAuth2Conf.tryToParseFromJson", () {
    test("reads the provider an application signs its users in with", () {
      final conf = DefaultOAuth2Conf.tryToParseFromJson(_json)!;

      expect(conf.clientId, "aClient");
      expect(conf.discoveryUrl, "https://a.provider/.well-known/openid-configuration");
      expect(conf.scopes, ["openid", "profile"]);
      expect(conf.appAuthRedirectScheme, "com.example.app");
      expect(conf.issuer, isNull);
      expect(conf.providerUrlConf, isNull);
    });

    test("reads a provider which is named by its issuer", () {
      final json = _confWithout("discoveryUrl", and: {"issuer": "https://a.provider"});

      final conf = DefaultOAuth2Conf.tryToParseFromJson(json)!;

      expect(conf.issuer, "https://a.provider");
      expect(conf.discoveryUrl, isNull);
    });

    test("reads a provider whose endpoints are named one by one", () {
      final json = _confWithout(
        "discoveryUrl",
        and: {
          "serviceConfiguration": {
            "authorizationEndpoint": "https://a.provider/authorize",
            "tokenEndpoint": "https://a.provider/token",
          },
        },
      );

      final conf = DefaultOAuth2Conf.tryToParseFromJson(json)!;

      expect(conf.providerUrlConf?.tokenEndpoint, "https://a.provider/token");
    });

    test("takes the issuer of the package which knows the provider", () {
      final json = _confWithout("discoveryUrl");

      final conf = DefaultOAuth2Conf.tryToParseFromJson(json, defaultIssuer: "https://a.provider")!;

      expect(conf.issuer, "https://a.provider");
    });

    test("keeps the issuer of the application over the one of the package", () {
      final json = _confWithout("discoveryUrl", and: {"issuer": "https://another.provider"});

      final conf = DefaultOAuth2Conf.tryToParseFromJson(json, defaultIssuer: "https://a.provider")!;

      expect(conf.issuer, "https://another.provider");
    });

    test("refuses a configuration which names no client", () {
      expect(DefaultOAuth2Conf.tryToParseFromJson(_confWithout("clientId")), isNull);
    });

    test("refuses a configuration which names no scope", () {
      expect(DefaultOAuth2Conf.tryToParseFromJson(_confWithout("scopes")), isNull);
    });

    test("refuses a configuration which names no scheme to come back to", () {
      expect(DefaultOAuth2Conf.tryToParseFromJson(_confWithout("appAuthRedirectScheme")), isNull);
    });

    test("refuses a configuration which says nothing about where the provider is", () {
      expect(DefaultOAuth2Conf.tryToParseFromJson(_confWithout("discoveryUrl")), isNull);
    });

    test("refuses a configuration whose endpoints cannot be read", () {
      final json = _confWithout(
        "discoveryUrl",
        and: {
          "serviceConfiguration": {"tokenEndpoint": "https://a.provider/token"},
        },
      );

      expect(DefaultOAuth2Conf.tryToParseFromJson(json), isNull);
    });

    test("refuses a value which is not of the type the key carries", () {
      final json = _confWithout("clientId", and: {"clientId": 42});

      expect(DefaultOAuth2Conf.tryToParseFromJson(json), isNull);
    });
  });

  group("DefaultOAuth2Conf", () {
    test("is the same configuration as another one which names the same provider", () {
      expect(
        DefaultOAuth2Conf.tryToParseFromJson(_json),
        DefaultOAuth2Conf.tryToParseFromJson(_json),
      );
    });

    test("is another configuration as soon as the client differs", () {
      final json = _confWithout("clientId", and: {"clientId": "anotherClient"});

      expect(
        DefaultOAuth2Conf.tryToParseFromJson(_json),
        isNot(DefaultOAuth2Conf.tryToParseFromJson(json)),
      );
    });
  });
}
