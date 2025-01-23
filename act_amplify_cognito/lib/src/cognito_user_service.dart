// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_dart_utility/act_dart_utility_ext.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This service manages the interaction with the user currently log in
class CognitoUserService extends AbstractService {
  /// This is the separator in the identity id between the region and the user uuid
  static const _identityIdRegionSeparator = ":";

  /// This is the Cognito service logs helper
  final LogsHelper logsHelper;

  /// Class constructor
  CognitoUserService({
    required this.logsHelper,
  }) : super();

  /// Service init method
  @override
  Future<void> initService() async {}

  /// Test if an user is signed to the app (or not)
  Future<bool> isUserSigned() async {
    AuthSession amplifyResult;
    try {
      amplifyResult = await Amplify.Auth.fetchAuthSession();
    } on AuthException catch (e) {
      logsHelper.d("Error retrieving auth session: ${e.message}");
      return false;
    }

    return amplifyResult.isSignedIn;
  }

  /// {@template CognitoUserService.getCurrentUserId}
  /// Get the identity id of the current user
  ///
  /// If [includeRegion] is equals to true, the id retrieved will look like this:
  /// us-west-2:d2cf2506-40fc-c9e7-2bb5-d09d109fbe16
  /// If [includeRegion] is equals to false, only the UUID part will be returned
  /// {@endtemplate}
  Future<String?> getCurrentUserId({
    bool includeRegion = true,
  }) async {
    String userId;
    try {
      final amplifyResult = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      userId = amplifyResult.userPoolTokensResult.value.userId;
    } on AuthException catch (e) {
      logsHelper.d("Error retrieving auth session: ${e.message}");
      return null;
    }

    if (!includeRegion) {
      // The identity id looks like this: us-west-2:d2cf2506-40fc-c9e7-2bb5-d09d109fbe16
      // If we are here, that means we want to remove the first part and only get the uuid
      userId = userId.split(_identityIdRegionSeparator).last;
    }

    return userId;
  }

  /// Get the access token of the logged user
  ///
  /// Return null if no user is logged or if a problem occurred
  Future<String?> getAccessToken() async {
    String token;
    try {
      final amplifyResult = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      token = amplifyResult.userPoolTokensResult.value.accessToken.raw;
    } on AuthException catch (e) {
      logsHelper.d("Error retrieving auth session: ${e.message}");
      return null;
    }

    return token;
  }

  /// Get email address of currently logged user
  ///
  /// A user must be connected to call this method.
  /// Returns null if no users are logged in, if account has no known emails (unlikely)
  /// or if a problem occurred
  Future<String?> getEmailAddress() async {
    try {
      final amplifyResult = await Amplify.Auth.fetchUserAttributes();
      return amplifyResult
          .firstWhereOrNull((attribute) => attribute.userAttributeKey == AuthUserAttributeKey.email)
          ?.value;
    } on AuthException catch (e) {
      logsHelper.d("Error retrieving user email address: ${e.message}");
      return null;
    }
  }

  /// Change email address of currently logged user
  ///
  /// A user must be connected to call this method.
  /// [address] should be a valid email address.
  ///
  /// If a confirmation code is required, it is automatically sent and result states that
  /// a subsequent call to [confirmEmailAddressUpdate] is needed to provide received code.
  /// In such case, email address modification only occurs when confirmation is over.
  /// Also, email address conflict if any may be lately reported, by confirmation method.
  Future<AuthPropertyResult> setEmailAddress(String address) async {
    // Cognito bug/feature avoidance: asking for an empty or spaces-only email address
    // clears user email and returns success.
    // When user pool is configured as email-centric, this make it quite difficult to recover the
    // account if user signs out before resetting a proper email. Signing in with Cognito user UUID
    // is an option on the paper, but user have no knowledge of it.
    // This dangerous behavior deserves a dedicated clearEmailAddress function if needed one day.
    if (address.trim().isEmpty) {
      // We hope UI to act as a guard against this bad use case, therefore an assert is enough
      assert(false, "setEmailAddress rejects clearing email attempts");
      return const AuthPropertyResult(status: AuthPropertyStatus.badArgument);
    }

    try {
      final amplifyResult = await Amplify.Auth.updateUserAttribute(
        userAttributeKey: AuthUserAttributeKey.email,
        value: address,
      );
      return amplifyResult.nextStep.updateAttributeStep == AuthUpdateAttributeStep.done
          ? const AuthPropertyResult(status: AuthPropertyStatus.done)
          : AuthPropertyResult(
              status: AuthPropertyStatus.confirmWithCode,
              extra: amplifyResult,
            );
    } on AuthException catch (e) {
      logsHelper.d("Error modifying user email address: ${e.message}");
      return AuthPropertyResult(status: _parsePropertyException(e), extra: e);
    }
  }

  /// Confirm email address change of currently logged user
  ///
  /// A user must be connected to call this method.
  /// You may need to call this method after [setEmailAddress], depending on its result.
  Future<AuthPropertyResult> confirmEmailAddressUpdate({required String code}) async {
    try {
      final _ = await Amplify.Auth.confirmUserAttribute(
        userAttributeKey: AuthUserAttributeKey.email,
        confirmationCode: code,
      );
      return const AuthPropertyResult(status: AuthPropertyStatus.done);
    } on AuthException catch (e) {
      logsHelper.d("Error modifying user email address: ${e.message}");
      return AuthPropertyResult(status: _parsePropertyException(e), extra: e);
    }
  }

  /// This parses the received error to a [AuthPropertyStatus]
  static AuthPropertyStatus _parsePropertyException(AuthException exception) => switch (exception) {
        AliasExistsException _ => AuthPropertyStatus.accountPropertyConflict,
        CodeMismatchException _ => AuthPropertyStatus.wrongConfirmationCode,
        InvalidParameterException _ => AuthPropertyStatus.badArgument,
        NetworkException _ => AuthPropertyStatus.networkError,
        _ => AuthPropertyStatus.genericError,
      };
}
