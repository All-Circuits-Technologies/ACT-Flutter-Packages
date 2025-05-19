// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/src/mixins/mixin_auth_local_storage_conf.dart';
import 'package:act_shared_auth_local_storage/src/mixins/mixin_auth_secrets.dart';
import 'package:act_shared_auth_local_storage/src/models/auth_user_ids.dart';

/// This is the implementation of [MixinAuthStorageService] with the secure local storage
class SecureLocalAuthStorage<C extends MixinAuthLocalStorageConf, S extends MixinAuthSecrets>
    with MixinAuthStorageService {
  /// The config manager
  final C _confManager;

  /// The secrets manager
  final S _secretsManager;

  /// Class constructor
  SecureLocalAuthStorage()
    : _confManager = globalGetIt().get<C>(),
      _secretsManager = globalGetIt().get<S>();

  /// {@macro act_shared_auth.MixinAuthStorageService.isUserIdsStorageSupported}
  @override
  Future<bool> isUserIdsStorageSupported() async => _confManager.saveUserIdsInStorage.load();

  /// {@macro act_shared_auth.MixinAuthStorageService.storeTokens}
  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    await _secretsManager.authTokens.store(tokens);
    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadTokens}
  @override
  Future<AuthTokens?> loadTokens() async => _secretsManager.authTokens.load();

  /// {@macro act_shared_auth.MixinAuthStorageService.clearTokens}
  @override
  Future<void> clearTokens() async => _secretsManager.authTokens.delete();

  /// {@macro act_shared_auth.MixinAuthStorageService.storeTokens}
  @override
  Future<bool> storeUserIds({required String username, required String password}) async {
    final isStorageSupported = await isUserIdsStorageSupported();
    if (!isStorageSupported) {
      appLogger().w("The storage of the user ids isn't supported, can't store the information");
      return false;
    }

    await _secretsManager.authIds.store(AuthUserIds(username: username, password: password));
    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadUserIds}
  @override
  Future<({String password, String username})?> loadUserIds() async {
    final isStorageSupported = await isUserIdsStorageSupported();
    if (!isStorageSupported) {
      appLogger().w("The storage of the user ids isn't supported, can't load the information");
      return null;
    }

    final userIds = await _secretsManager.authIds.load();
    if (userIds == null) {
      // No auth ids stored in memory
      return null;
    }

    return (username: userIds.username, password: userIds.password);
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.clearUserIds}
  @override
  Future<void> clearUserIds() async {
    final isStorageSupported = await isUserIdsStorageSupported();
    if (!isStorageSupported) {
      appLogger().w("The storage of the user ids isn't supported, can't clear the information");
      return;
    }

    await _secretsManager.authIds.delete();
  }
}
