// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/act_shared_auth_local_storage.dart';

/// This mixin adds the secret item the Keycloak tokens are kept in.
///
/// An application which signs in through the broker holds two sets of tokens: the ThingsBoard
/// ones, which [MixinAuthSecrets.authTokens] keeps and which the rest of the application signs its
/// calls with, and the Keycloak ones, which only the provider and the broker ever read. They are
/// kept under two distinct keys, because one set outliving the other is exactly what the refresh
/// ladder lives on.
mixin MixinKeycloakAuthSecrets on MixinAuthSecrets {
  /// This is the pair of Keycloak tokens of the current user, which the identity provider minted
  /// and the broker is called with.
  final keycloakTokens = const SecretItemWithParser<AuthTokens, String>(
    "KC_AUTH_TOKENS",
    parser: MemoryStorageUtility.convertAuthTokensFromStorage,
    castTo: MemoryStorageUtility.convertAuthTokensForStorage,
    doNotMigrate: true,
  );
}
