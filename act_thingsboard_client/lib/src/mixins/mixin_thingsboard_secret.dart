// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_stores_manager/act_stores_manager.dart';

/// This mixin contains all the secrets store variables needed by the ACT Thingsboard package
mixin MixinThingsboardSecret<
    S extends AbstractSecretsManager,
    P extends AbstractPropertiesManager,
    E extends MixinStoresEnv> on AbstractSecretsManager<P, E> {
  /// This is the JWT linked to the current Thingsboard user stored in memory
  final tbToken = SecretItem<String, S>("TB_TOKEN");

  /// This is the refresh JWT linked to the current Thingsboard user stored in memory
  final tbRefreshToken = SecretItem<String, S>("TB_REFRESH_TOKEN");

  /// This is the username stored in memory of the current Thingsboard user
  final username = SecretItem<String, S>("TB_USERNAME");

  /// This is the password stored in memory of the current Thingsboard user
  final password = SecretItem<String, S>("TB_PASSWORD");
}
