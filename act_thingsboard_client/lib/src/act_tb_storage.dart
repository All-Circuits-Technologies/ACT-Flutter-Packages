// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_stores_manager/act_stores_manager.dart';
import 'package:act_thingsboard_client/src/mixins/mixin_thingsboard_secret.dart';
import 'package:thingsboard_client/thingsboard_client.dart';

/// This class allows to override the default behaviour of Thingsboard when saving JWT token to
/// memory
class ActTbStorage<S extends MixinThingsboardSecret> extends TbStorage {
  /// This is the key used by the Thingsboard library to store the JWT token
  static const _tokenTbKey = "jwt_token";

  /// This is the key used by the Thingsboard library to store the refresh JWT token
  static const _refreshTokenTbKey = "refresh_token";

  /// The Thingsboard secret manager
  final S _tbSecretManager;

  /// Class constructor
  ActTbStorage({required S tbSecretManager})
      : _tbSecretManager = tbSecretManager;

  /// Called to delete the content of an item
  @override
  Future<void> deleteItem(String key) async => _getSecretItem(key).delete();

  /// Called to get the content of an item
  @override
  Future<String?> getItem(String key) async => _getSecretItem(key).load();

  /// Called to set the content of an item
  @override
  Future<void> setItem(String key, String value) =>
      _getSecretItem(key).store(value);

  /// Get the secret item linked to the Thingsboard key
  SecretItem<String, S> _getSecretItem<T>(String key) {
    switch (key) {
      case _tokenTbKey:
        return _tbSecretManager.tbToken as SecretItem<String, S>;
      case _refreshTokenTbKey:
        return _tbSecretManager.tbRefreshToken as SecretItem<String, S>;
      default:
        throw Exception(
            "The wanted secret item searched with the key: $key, doesn't exist and it's "
            "not managed");
    }
  }
}
