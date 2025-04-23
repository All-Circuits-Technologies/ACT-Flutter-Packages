// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import "package:act_local_storage_manager/act_local_storage_manager.dart";
import "package:act_oauth2_core/src/models/oauth2_tokens.dart";

/// This mixin contains all the secrets store variables needed by the ACT Thingsboard package
mixin MixinOAuth2TokensSecret<P extends AbstractPropertiesManager, E extends MixinStoresConf>
    on AbstractSecretsManager<P, E> {
  final oauth2Tokens = SecretItem<OAuth2Tokens>(
    "OAUTH2_TOKENS",
    parser: OAuth2Tokens.fromStringifiedJson,
    castTo: OAuth2Tokens.parseToString,
  );
}
