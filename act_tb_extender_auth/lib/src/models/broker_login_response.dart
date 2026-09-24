// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_tb_extender_auth/src/models/broker_user.dart';
import 'package:equatable/equatable.dart';

/// The success payload the `POST /api/v1/auth/login` endpoint of the tb-extender auth broker
/// answers.
///
/// It carries the freshly minted ThingsBoard tokens and the [BrokerUser] they belong to.
class BrokerLoginResponse extends Equatable {
  /// This is the key used to parse the ThingsBoard access token from a JSON object
  static const _tbTokenKey = "tbToken";

  /// This is the key used to parse the ThingsBoard refresh token from a JSON object
  static const _tbRefreshTokenKey = "tbRefreshToken";

  /// This is the key used to parse the lifetime of the token, in seconds, from a JSON object
  static const _expiresInKey = "expiresIn";

  /// This is the key used to parse the user object from a JSON object
  static const _userKey = "user";

  /// This is the ThingsBoard access token (JWT).
  final String tbToken;

  /// This is the ThingsBoard refresh token (JWT).
  final String tbRefreshToken;

  /// This is the lifetime of the ThingsBoard access token, in seconds.
  final int expiresIn;

  /// This is the user information linked to the tokens.
  final BrokerUser user;

  /// Class constructor
  const BrokerLoginResponse({
    required this.tbToken,
    required this.tbRefreshToken,
    required this.expiresIn,
    required this.user,
  });

  /// Try to parse the [BrokerLoginResponse] from a [json] object.
  ///
  /// Return null when a mandatory field is missing or malformed.
  static BrokerLoginResponse? fromJson(Map<String, dynamic> json) {
    final logger = appLogger();

    final tbToken = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _tbTokenKey,
      logger: logger,
    );

    final tbRefreshToken = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _tbRefreshTokenKey,
      logger: logger,
    );

    final expiresIn = JsonUtility.getNotNullOnePrimaryElement<int>(
      json: json,
      key: _expiresInKey,
      logger: logger,
    );

    final userResult = JsonUtility.getOneElement<BrokerUser, Map<String, dynamic>>(
      json: json,
      key: _userKey,
      castValueFunc: BrokerUser.fromJson,
      logger: logger,
    );

    if (tbToken == null ||
        tbRefreshToken == null ||
        expiresIn == null ||
        !userResult.isOk ||
        userResult.value == null) {
      logger.w("Can't parse the broker login response, a mandatory field is missing in the JSON");
      return null;
    }

    return BrokerLoginResponse(
      tbToken: tbToken,
      tbRefreshToken: tbRefreshToken,
      expiresIn: expiresIn,
      user: userResult.value!,
    );
  }

  /// Object properties
  @override
  List<Object?> get props => [tbToken, tbRefreshToken, expiresIn, user];
}
