// SPDX-FileCopyrightText: 2026 Dorian Benech <dorian.benech@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_jwt_utilities/act_jwt_utilities.dart';
import 'package:equatable/equatable.dart';

/// The user information the tb-extender auth broker answers beside the ThingsBoard tokens.
///
/// This mirrors the `user` object of the success payload of `POST /api/v1/auth/login`.
class BrokerUser extends Equatable {
  /// This is the key used to parse the ThingsBoard user id from a JSON object
  static const _tbUserIdKey = "tbUserId";

  /// This is the key used to parse the ThingsBoard customer id from a JSON object
  static const _customerIdKey = "customerId";

  /// This is the key used to parse the email from a JSON object
  static const _emailKey = "email";

  /// This is the key used to parse the first name from a JSON object
  static const _firstNameKey = "firstName";

  /// This is the key used to parse the last name from a JSON object
  static const _lastNameKey = "lastName";

  /// This is the claim of a ThingsBoard token which names the user id
  static const _tbUserIdClaim = "userId";

  /// This is the claim of a ThingsBoard token which names the customer id
  static const _tbCustomerIdClaim = "customerId";

  /// ThingsBoard names the email of the user as the subject of its tokens
  static const _tbEmailClaim = "sub";

  /// This is the ThingsBoard user id (UUID) of the signed in user.
  final String tbUserId;

  /// This is the ThingsBoard customer id (UUID) the user belongs to.
  final String customerId;

  /// This is the email address of the signed in user.
  final String email;

  /// This is the first name of the user, when the broker gives one.
  final String? firstName;

  /// This is the last name of the user, when the broker gives one.
  final String? lastName;

  /// Class constructor
  const BrokerUser({
    required this.tbUserId,
    required this.customerId,
    required this.email,
    this.firstName,
    this.lastName,
  });

  /// Try to parse the [BrokerUser] from a [json] object.
  ///
  /// Return null when a mandatory field is missing or malformed.
  static BrokerUser? fromJson(Map<String, dynamic> json) {
    final logger = appLogger();

    final tbUserId = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _tbUserIdKey,
      logger: logger,
    );

    final customerId = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _customerIdKey,
      logger: logger,
    );

    final email = JsonUtility.getNotNullOnePrimaryElement<String>(
      json: json,
      key: _emailKey,
      logger: logger,
    );

    final firstNameResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _firstNameKey,
      canBeUndefined: true,
      logger: logger,
    );

    final lastNameResult = JsonUtility.getOnePrimaryElement<String>(
      json: json,
      key: _lastNameKey,
      canBeUndefined: true,
      logger: logger,
    );

    if (tbUserId == null ||
        customerId == null ||
        email == null ||
        !firstNameResult.isOk ||
        !lastNameResult.isOk) {
      logger.w("Can't parse the broker user, a mandatory field is missing in the given JSON");
      return null;
    }

    return BrokerUser(
      tbUserId: tbUserId,
      customerId: customerId,
      email: email,
      firstName: firstNameResult.value,
      lastName: lastNameResult.value,
    );
  }

  /// Object properties
  /// Read the user the claims of the ThingsBoard access token [rawTbToken] name.
  ///
  /// The broker names the user at a login only; a run which starts from the tokens a previous one
  /// kept reads it here. Return null when the token isn't a JWT or misses one of the claims.
  static BrokerUser? tryFromTbToken(String rawTbToken) {
    final payload = JwtParserUtility.tryToParseToken(rawTbToken)?.payload;
    if (payload is! Map) {
      return null;
    }

    final tbUserId = payload[_tbUserIdClaim];
    final customerId = payload[_tbCustomerIdClaim];
    final email = payload[_tbEmailClaim];
    if (tbUserId is! String || customerId is! String || email is! String) {
      return null;
    }

    final firstName = payload[_firstNameKey];
    final lastName = payload[_lastNameKey];

    return BrokerUser(
      tbUserId: tbUserId,
      customerId: customerId,
      email: email,
      firstName: (firstName is String) ? firstName : null,
      lastName: (lastName is String) ? lastName : null,
    );
  }

  @override
  List<Object?> get props => [tbUserId, customerId, email, firstName, lastName];
}
