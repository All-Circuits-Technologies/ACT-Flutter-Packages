// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_oauth2_core/src/models/provider_url_conf.dart';
import 'package:act_test_utility/act_test_utility.dart';
import 'package:flutter_test/flutter_test.dart';

/// The URLs of a provider, as an application writes them in its configuration.
const _json = <String, dynamic>{
  "authorizationEndpoint": "https://a.provider/authorize",
  "tokenEndpoint": "https://a.provider/token",
  "endSessionEndpoint": "https://a.provider/logout",
};

void main() {
  setUp(FakeGlobalManager.install);

  group("ProviderUrlConf.tryToParseFromJson", () {
    test("reads the endpoints of a provider", () {
      final conf = ProviderUrlConf.tryToParseFromJson(_json)!;

      expect(conf.authorizationEndpoint, "https://a.provider/authorize");
      expect(conf.tokenEndpoint, "https://a.provider/token");
      expect(conf.endSessionEndpoint, "https://a.provider/logout");
    });

    test("reads a provider which offers no way of ending a session", () {
      final json = Map<String, dynamic>.from(_json)..remove("endSessionEndpoint");

      expect(ProviderUrlConf.tryToParseFromJson(json)?.endSessionEndpoint, isNull);
    });

    test("refuses a provider which has no authorization endpoint", () {
      final json = Map<String, dynamic>.from(_json)..remove("authorizationEndpoint");

      expect(ProviderUrlConf.tryToParseFromJson(json), isNull);
    });

    test("refuses a provider which has no token endpoint", () {
      final json = Map<String, dynamic>.from(_json)..remove("tokenEndpoint");

      expect(ProviderUrlConf.tryToParseFromJson(json), isNull);
    });

    test("refuses an endpoint which is not written as a URL", () {
      final json = Map<String, dynamic>.from(_json)..["tokenEndpoint"] = 42;

      expect(ProviderUrlConf.tryToParseFromJson(json), isNull);
    });
  });

  group("ProviderUrlConf.toServiceConf", () {
    test("hands the endpoints to the library which speaks to the provider", () {
      final serviceConf = ProviderUrlConf.tryToParseFromJson(_json)!.toServiceConf();

      expect(serviceConf.authorizationEndpoint, "https://a.provider/authorize");
      expect(serviceConf.tokenEndpoint, "https://a.provider/token");
      expect(serviceConf.endSessionEndpoint, "https://a.provider/logout");
    });
  });

  group("ProviderUrlConf", () {
    test("is the same configuration as another one with the same endpoints", () {
      expect(ProviderUrlConf.tryToParseFromJson(_json), ProviderUrlConf.tryToParseFromJson(_json));
    });

    test("is another configuration as soon as an endpoint differs", () {
      final json = Map<String, dynamic>.from(_json)
        ..["tokenEndpoint"] = "https://another.provider/token";

      expect(
        ProviderUrlConf.tryToParseFromJson(_json),
        isNot(ProviderUrlConf.tryToParseFromJson(json)),
      );
    });
  });
}
