// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_oauth2_google/act_oauth2_google.dart';
import 'package:act_test_utility/act_test_utility.dart';

/// The asset key of the configuration file the tests serve.
const configKey = "assets/config/default.yaml";

/// The configuration of an application whose users sign in with Google.
const aGoogleConf = """
auth:
  oauth2:
    google:
      config:
        clientId: "a-client-id"
        appAuthRedirectScheme: "com.example.app"
        scopes:
          - openid
          - email
""";

/// The configuration which names the Google client of an application under test.
class FakeGoogleConfigManager extends AbstractConfigManager with MixinGoogleOAuth2Conf {
  /// Class constructor
  FakeGoogleConfigManager() : super(logger: const SilentLogger());

  /// Serves [content] as the configuration file of the application and returns the manager which
  /// reads it.
  ///
  /// The caller has to stop serving the assets and to dispose the manager once the test is over.
  static Future<FakeGoogleConfigManager> withContent(String content) async {
    FakeAssets.serve({configKey: content});

    final manager = FakeGoogleConfigManager();
    await manager.initLifeCycle();

    return manager;
  }
}
