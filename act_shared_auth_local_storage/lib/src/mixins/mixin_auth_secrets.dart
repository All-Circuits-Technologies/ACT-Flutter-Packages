// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import "package:act_local_storage_manager/act_local_storage_manager.dart";
import "package:act_shared_auth/act_shared_auth.dart";
import "package:act_shared_auth_local_storage/src/models/auth_user_ids.dart";
import "package:act_shared_auth_local_storage/src/utilities/memory_storage_utility.dart";

/// This mixin adds secret items to storage the auth tokens and ids (username + password)
mixin MixinAuthSecrets<P extends AbstractPropertiesManager, E extends MixinStoresConf>
    on AbstractSecretsManager<P, E> {
  /// This is the tokens of the current user used to contact the server
  final authTokens = const SecretItem<AuthTokens>(
    "AUTH_TOKENS",
    parser: MemoryStorageUtility.convertAuthTokensFromStorage,
    castTo: MemoryStorageUtility.convertAuthTokensForStorage,
    doNotMigrate: true,
  );

  /// This is the ids of the current user used to get the tokens on the server
  ///
  /// This element is only used if we approve the storage of user ids.
  final authIds = const SecretItem<AuthUserIds>(
    "AUTH_IDS",
    parser: MemoryStorageUtility.convertAuthUserIdsFromStorage,
    castTo: MemoryStorageUtility.convertAuthUserIdsForStorage,
  );
}
