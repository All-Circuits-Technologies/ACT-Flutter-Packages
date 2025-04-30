// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This class allows to override the default behaviour of Thingsboard when saving JWT token to
/// memory
class ActTbStorage extends TbStorage<String> {
  /// This is the key used by the Thingsboard library to store the JWT token
  static const _tokenTbKey = "jwt_token";

  /// This is the key used by the Thingsboard library to store the refresh JWT token
  static const _refreshTokenTbKey = "refresh_token";

  final MixinAuthStorageService? _storageService;

  /// Class constructor
  ActTbStorage({required MixinAuthStorageService? storageService})
      : _storageService = storageService;

  /// Called to delete the content of an item
  @override
  Future<void> deleteItem(String key) async => _clearTokenItem(key);

  /// Called to get the content of an item
  @override
  Future<String?> getItem(String key, {String? defaultValue}) async {
    final token = await _tryToGetTokenItem(key);

    return token?.raw ?? defaultValue;
  }

  /// Called to set the content of an item
  @override
  Future<void> setItem(String key, String value) async => _storeTokenItem(key, value);

  /// Test if the [key] exists in the storage
  @override
  Future<bool> containsKey(String key) async {
    final token = await _tryToGetTokenItem(key);
    return token != null;
  }

  /// Get the secret item linked to the Thingsboard key
  Future<AuthToken?> _tryToGetTokenItem(String key) async {
    final tokens = await _storageService?.loadTokens();
    if (tokens == null) {
      // No need to go further, there are no tokens to load
      return null;
    }

    switch (key) {
      case _tokenTbKey:
        return tokens.accessToken;
      case _refreshTokenTbKey:
        return tokens.refreshToken;
      default:
        return null;
    }
  }

  Future<bool> _storeTokenItem(String key, String value) async {
    if (_storageService == null) {
      // No need to go further, there is no storage service
      return false;
    }

    var tokens = (await _storageService!.loadTokens()) ?? const AuthTokens();

    switch (key) {
      case _tokenTbKey:
        tokens = tokens.copyWith(accessToken: AuthToken(raw: value));
        break;
      case _refreshTokenTbKey:
        tokens = tokens.copyWith(refreshToken: AuthToken(raw: value));
        break;
      default:
        return false;
    }

    return _storageService!.storeTokens(tokens: tokens);
  }

  Future<void> _clearTokenItem(String key) async {
    var tokens = await _storageService?.loadTokens();
    if (tokens == null) {
      // No need to go further, there is no element to clear
      return;
    }

    switch (key) {
      case _tokenTbKey:
        tokens = tokens.copyWith(forceAccessTokenValue: true);
        break;
      case _refreshTokenTbKey:
        tokens = tokens.copyWith(forceRefreshTokenValue: true);
        break;
      default:
        return;
    }

    await _storageService!.storeTokens(tokens: tokens);
  }
}
