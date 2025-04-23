// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_local_storage_manager/act_local_storage_manager.dart';
import 'package:act_thingsboard_client/src/mixins/mixin_thingsboard_secret.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This class allows to override the default behaviour of Thingsboard when saving JWT token to
/// memory
class ActTbStorage extends TbStorage<String> {
  /// This is the key used by the Thingsboard library to store the JWT token
  static const _tokenTbKey = "jwt_token";

  /// This is the key used by the Thingsboard library to store the refresh JWT token
  static const _refreshTokenTbKey = "refresh_token";

  /// The Thingsboard secret manager
  final MixinThingsboardSecret _tbSecretManager;

  /// Class constructor
  ActTbStorage({required MixinThingsboardSecret tbSecretManager})
      : _tbSecretManager = tbSecretManager;

  /// Called to delete the content of an item
  @override
  Future<void> deleteItem(String key) async => _getSecretItem(key).delete();

  /// Called to get the content of an item
  @override
  Future<String?> getItem(String key, {String? defaultValue}) async => _getSecretItem(key).load();

  /// Called to set the content of an item
  @override
  Future<void> setItem(String key, String value) => _getSecretItem(key).store(value);

  /// Test if the [key] exists in the storage
  @override
  bool containsKey(String key) {
    final secretItem = _tryToGetSecretItem(key);
    return secretItem != null;
  }

  /// Get the secret item linked to the Thingsboard key
  SecretItem<String> _getSecretItem<T>(String key) {
    final secretItem = _tryToGetSecretItem(key);
    if (secretItem == null) {
      throw Exception("The wanted secret item searched with the key: $key, doesn't exist and it's "
          "not managed");
    }

    return secretItem;
  }

  /// Get the secret item linked to the Thingsboard key
  SecretItem<String>? _tryToGetSecretItem<T>(String key) {
    switch (key) {
      case _tokenTbKey:
        return _tbSecretManager.tbToken;
      case _refreshTokenTbKey:
        return _tbSecretManager.tbRefreshToken;
      default:
        return null;
    }
  }
}
