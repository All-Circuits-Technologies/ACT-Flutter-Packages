// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_local_storage_manager/src/storage_constants.dart' as storage_constants;

/// This mixin contains the [NotNullableConfigVar] object used in the [act_store_manager] package
///
/// When using the [act_store_manager] package, in your project you have to use this mixin on your
/// implementation of [AbstractEnvManager]
mixin MixinStoresConf on AbstractConfigManager {
  /// True to clean all the secret storage when reinstalling the app
  final cleanSecretStorageWhenReinstall = const NotNullableConfigVar<bool>(
    'stores.secrets.cleanWhenReInstall',
    defaultValue: storage_constants.defaultCleanSecretStorageWhenReinstallValue,
  );
}
