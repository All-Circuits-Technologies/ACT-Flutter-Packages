// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_oauth2_google/src/data/google_url_constants.dart' as google_url_constants;

/// This mixin adds a config for the OAuth2 Google
mixin MixinGoogleOAuth2Conf on AbstractConfigManager {
  /// This is the configuration to communicate with the OAuth2 Google provider
  final oauthClientConf = ParserConfigVar<DefaultOAuth2Conf, Map<String, dynamic>>(
    "auth.oauth2.google.config",
    parser:
        (value) => DefaultOAuth2Conf.tryToParseFromJson(
          value,
          defaultIssuer: google_url_constants.googleIssuerUrl,
        ),
  );
}
