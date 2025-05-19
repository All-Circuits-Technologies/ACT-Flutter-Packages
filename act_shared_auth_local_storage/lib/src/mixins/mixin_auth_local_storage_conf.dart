// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_shared_auth_local_storage/src/constants/auth_local_storage_constants.dart'
    as auth_local_storage_constants;

/// This mixin adds configuration to the [AbstractConfigManager] for the secure local auth storage
mixin MixinAuthLocalStorageConf on AbstractConfigManager {
  /// True to accept the storage of used ids (username and password) in the secure local storage of
  /// the phone.
  final saveUserIdsInStorage = const NotNullableConfigVar<bool>(
    'auth.secrets.localStorage.saveUserIds',
    defaultValue: auth_local_storage_constants.saveUserIdsDefaultValue,
  );
}
