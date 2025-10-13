// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/src/utilities/memory_storage_utility.dart';

/// The mixin add secret items to a not secured storage. It only adds the auth tokens.
mixin MixinAuthNotSecuredSecrets on AbstractPropertiesManager {
  /// This is the tokens of the current user used to contact the server
  final authTokens = SharedPrefsItemWithParser<AuthTokens, String>(
    "NOT_SECURED_AUTH_TOKENS",
    parser: MemoryStorageUtility.convertAuthTokensFromStorage,
    castTo: MemoryStorageUtility.convertAuthTokensForStorage,
  );
}
