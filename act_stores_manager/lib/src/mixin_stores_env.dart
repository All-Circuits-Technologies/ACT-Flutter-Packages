// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_env_manager/act_env_manager.dart';
import 'package:act_stores_manager/src/storage_constants.dart' as storage_constants;

/// This mixin contains the [NotNullableEnvVar] object used in the [act_store_manager] package
///
/// When using the [act_store_manager] package, in your project you have to use this mixin on your
/// implementation of [AbstractEnvManager]
mixin MixinStoresEnv on AbstractEnvManager {
  /// True to clean all the secret storage when reinstalling the app
  final cleanSecretStorageWhenReinstall = NotNullableEnvVar<bool>(
    'CLEAN_SECRET_STORAGE_WHEN_REINSTALL',
    defaultValue: storage_constants.defaultCleanSecretStorageWhenReinstallValue,
  );
}
