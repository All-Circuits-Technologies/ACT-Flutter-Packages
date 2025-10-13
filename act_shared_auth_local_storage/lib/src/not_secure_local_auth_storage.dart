// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/src/mixins/mixin_auth_not_secured_secrets.dart';

/// This is the implementation of [MixinAuthStorageService] with the not secure local storage
///
/// The element stored can be accessed and read by other applications and/or user.
class NotSecureLocalAuthStorage<P extends MixinAuthNotSecuredSecrets> with MixinAuthStorageService {
  /// The properties manager
  final P _propertiesManager;

  /// Class constructor
  NotSecureLocalAuthStorage() : _propertiesManager = globalGetIt().get<P>();

  /// {@macro act_shared_auth.MixinAuthStorageService.isUserIdsStorageSupported}
  ///
  /// We don't support the storage of user ids in a not secure storage
  @override
  Future<bool> isUserIdsStorageSupported() async => false;

  /// {@macro act_shared_auth.MixinAuthStorageService.storeTokens}
  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    await _propertiesManager.authTokens.store(tokens);
    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadTokens}
  @override
  Future<AuthTokens?> loadTokens() async => _propertiesManager.authTokens.load();

  /// {@macro act_shared_auth.MixinAuthStorageService.clearTokens}
  @override
  Future<void> clearTokens() async => _propertiesManager.authTokens.delete();
}
