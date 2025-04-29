// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_shared_auth_local_storage/src/data/auth_local_storage_constants.dart'
    as auth_local_storage_constants;

mixin MixinAuthLocalStorageConf on AbstractConfigManager {
  /// True to clean all the secret storage when reinstalling the app
  final saveUserIdsInStorage = const NotNullableConfigVar<bool>(
    'auth.secrets.localStorage.saveUserIds',
    defaultValue: auth_local_storage_constants.saveUserIdsDefaultValue,
  );
}
