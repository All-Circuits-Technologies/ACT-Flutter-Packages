// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';

/// This mixin contains all the secrets store variables needed by the ACT Thingsboard package
mixin MixinThingsboardSecret<P extends AbstractPropertiesManager, E extends MixinStoresConf>
    on AbstractSecretsManager<P, E> {
  /// This is the JWT linked to the current Thingsboard user stored in memory
  final tbToken = const SecretItem<String>("TB_TOKEN");

  /// This is the refresh JWT linked to the current Thingsboard user stored in memory
  final tbRefreshToken = const SecretItem<String>("TB_REFRESH_TOKEN");

  /// This is the username stored in memory of the current Thingsboard user
  final username = const SecretItem<String>("TB_USERNAME");

  /// This is the password stored in memory of the current Thingsboard user
  final password = const SecretItem<String>("TB_PASSWORD");
}
