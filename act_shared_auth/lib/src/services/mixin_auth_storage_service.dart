// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';

/// This mixin has to be used by third party package when implementing shared authentication
/// storage.
///
/// This is used to conceptually separate the ids storage from the authentication requests.
mixin MixinAuthStorageService {
  /// {@template act_shared_auth.MixinAuthStorageService.isUserIdsStorageSupported}
  /// Says if the storage of user ids (username and password) is supported by the storage service.
  ///
  /// This allowed to only store tokens and not user ids in the user secure storage.
  /// {@endtemplate}
  Future<bool> isUserIdsStorageSupported() async => false;

  /// {@template act_shared_auth.MixinAuthStorageService.storeTokens}
  /// Store the tokens info in the user secure storage.
  ///
  /// Return true if no problem occurred.
  /// {@endtemplate}
  Future<bool> storeTokens({
    required AuthTokens tokens,
  });

  /// {@template act_shared_auth.MixinAuthStorageService.loadTokens}
  /// Load the tokens info in the user secure storage.
  ///
  /// Return null if a problem occurred in while parsing or if the element doesn't exist in memory.
  /// {@endtemplate}
  Future<AuthTokens?> loadTokens();

  /// {@template act_shared_auth.MixinAuthStorageService.clearTokens}
  /// Clear the tokens from memory.
  /// {@endtemplate}
  Future<void> clearTokens();

  /// {@template act_shared_auth.MixinAuthStorageService.storeUserIds}
  /// Store the user ids (username and password) info in the user secure storage.
  ///
  /// If you don't implement this method, be sure that [isUserIdsStorageSupported] isn't overridden
  /// or returns false.
  ///
  /// Return true if no problem occurred.
  /// {@endtemplate}
  Future<bool> storeUserIds({
    required String username,
    required String password,
  }) async =>
      _crashUnimplemented("storeUserIds");

  /// {@template act_shared_auth.MixinAuthStorageService.loadUserIds}
  /// Load the user ids (username and password) info from the user secure storage.
  ///
  /// If you don't implement this method, be sure that [isUserIdsStorageSupported] isn't overridden
  /// or returns false.
  ///
  /// Return null if a problem occurred or if the memory is empty.
  /// {@endtemplate}
  Future<({String username, String password})?> loadUserIds() async =>
      _crashUnimplemented("loadUserIds");

  /// {@template act_shared_auth.MixinAuthStorageService.clearUserIds}
  /// Clear the user ids (username and password) info from memory.
  ///
  /// If you don't implement this method, be sure that [isUserIdsStorageSupported] isn't overridden
  /// or returns false.
  /// {@endtemplate}
  Future<void> clearUserIds() async => _crashUnimplemented("clearUserIds");

  /// This trap forcibly crashes the app when unsupported methods are reached
  ///
  /// Service either misses this method implementation or it does not support it at all.
  /// If a service can support missing method but do not implement it yet, developer may want to
  /// implement it and return notSupportedYet error.
  Never _crashUnimplemented(String method) {
    final err = "$runtimeType service does not implement $method";
    assert(false, err);
    throw Exception(err);
  }
}
