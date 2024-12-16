// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This service manages the Cognito Sign-up methods
class CognitoSignUpService extends AbstractService {
  /// This is the Cognito service logs helper
  final LogsHelper logsHelper;

  /// Class constructor
  CognitoSignUpService({
    required this.logsHelper,
  }) : super();

  /// Service init method
  @override
  Future<void> initService() async {}

  /// User self-registration entry-point
  ///
  /// Depending on Cognito user pool creation settings (username-centric or email-centric),
  /// [accountId] must be either a uniquely chosen user identifier or an email address.
  ///
  /// Note that feeding user (initial) email address for [accountId] is denied with username-centric
  /// pools (detected and rejected) but mandatory with email-centric pools.
  /// Developers therefore must be aware of server-side user pool setup, which must be chosen
  /// carefully since this setting can only be chosen upon user pool creation.
  /// Note that [accountId] pattern for username-centric pools is r'[\p{L}\p{M}\p{S}\p{N}\p{P}]+',
  /// that is username is composed of Letters, Marks, Symbols, Numbers and Punctuations.
  ///
  /// [password] must comply with user pool rules. Also, leading and tailing spaces are rejected.
  ///
  /// Username-centric user pools may not require extra [email] but this is unlikely.
  /// Email-centric user pools somehow ignores the [email] argument, superseded by [accountId].
  /// If given with an email-centric user pool (useless but don't hurt), it must match [accountId].
  /// Cognito will likely verify the email address by sending a code and asking user to give it
  /// back through a subsequent [confirmSignUp] call.
  ///
  /// *Caution*: email address collision with username-centric pools is unfortunately not detected
  /// at [signUp] stage but by [confirmSignUp], which is a kind of nightmare since account
  /// is already created. Another [signUp] attempt with same [accountId] and another [email] dies
  /// in a [accountId] collision error and sign-in attempt requires the subsequent sign-up
  /// confirmation which can't succeed.
  ///
  /// Self-service sign-up feature must be enabled for user pool:
  /// Cognito > (your pool) > Sign-up experience > Self-service sign-up > enable
  ///
  /// Only default user pool is currently targeted (pool choice is not implemented yet).
  ///
  /// On success, Cognito account is created, likely in unconfirmed state until [confirmSignUp].
  /// If never confirmed, account will likely remains unconfirmed in the pool, locking [accountId].
  Future<AuthSignUpResult> signUp({
    required String accountId,
    required String password,
    String? email,
  }) async {
    if (accountId.isEmpty || password.isEmpty || (email != null && email.isEmpty)) {
      return const AuthSignUpResult(status: AuthSignUpStatus.badArgument);
    }

    SignUpResult amplifyResult;
    try {
      amplifyResult = await Amplify.Auth.signUp(
        username: accountId,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            if (email != null) AuthUserAttributeKey.email: email,
            // Other keys we may want to set one day:
            // - AuthUserAttributeKey.locale for user to get AWS mails in wanted language
            //   Something like dart:ui/PlatformDispatcher.locale.toLanguageTag()
            //   but we may not want to add ui dependency, therefore would be to be given by args
            //   as a bare String.
            // - name, family name, phone
            // TODO(aloiseau): Cognito signup: fill user locale
          },
        ),
      );
    } on AuthException catch (e) {
      logsHelper.e('Error sign-up: ${e.message}');
      return AuthSignUpResult(status: _parseException(e), extra: e);
    }

    return _handleSignUpResult(amplifyResult);
  }

  /// User self-registration second half
  ///
  /// [signUp] self-registration may require user to input a code received by mail or phone.
  /// This is the purpose of this method.
  ///
  /// [accountId] identifies account to confirm.
  /// [code] is the code sent to user by [signUp] procedure (likely into its mailbox)
  Future<AuthSignUpResult> confirmSignUp({
    required String accountId,
    required String code,
  }) async {
    if (accountId.isEmpty || code.isEmpty) {
      return const AuthSignUpResult(status: AuthSignUpStatus.badArgument);
    }

    SignUpResult? amplifyResult;
    try {
      amplifyResult = await Amplify.Auth.confirmSignUp(
        username: accountId,
        confirmationCode: code,
      );
    } on AuthException catch (e) {
      logsHelper.e('Error sign-up confirmation: ${e.message}');
      return AuthSignUpResult(status: _parseException(e), extra: e);
    }

    return _handleSignUpResult(amplifyResult);
  }

  /// Re-ask a sign-up confirmation code
  ///
  /// Confirmation code sent by [signUp] may not have reached its destination.
  /// This method can cope with a transient delivery failure by resending a code.
  ///
  /// [accountId] identifies account to confirm. Some services may also accept user email or phone.  Future<AuthSignUpResult> resendSignUpCode({
  Future<AuthSignUpResult> resendSignUpCode({
    required String accountId,
  }) async {
    if (accountId.isEmpty) {
      return const AuthSignUpResult(status: AuthSignUpStatus.badArgument);
    }

    // Note that resendSignUpCode calls gives a custom result which does not contain any success
    // or failure information. It only contains details about where code has been sent.
    ResendSignUpCodeResult? amplifyResult;
    try {
      amplifyResult = await Amplify.Auth.resendSignUpCode(
        username: accountId,
      );
    } on AuthException catch (e) {
      logsHelper.e('Error sign-up confirmation: ${e.message}');
      return AuthSignUpResult(status: _parseException(e), extra: e);
    }

    return _handleSignUpCodeResult(amplifyResult);
  }

  /// The sign-up process can be in several steps, this method parses the result received from sign
  /// up call and say what need to be done next. It choose the right [AuthSignUpStatus]
  Future<AuthSignUpResult> _handleSignUpResult(SignUpResult result) async {
    if (result.isSignUpComplete) {
      return const AuthSignUpResult(status: AuthSignUpStatus.done);
    }

    switch (result.nextStep.signUpStep) {
      case AuthSignUpStep.confirmSignUp:
        return const AuthSignUpResult(status: AuthSignUpStatus.confirmSignUpWithCode);
      case AuthSignUpStep.done:
        return const AuthSignUpResult(status: AuthSignUpStatus.done);
    }
  }

  /// The sign-up process can be in several steps, this method parses the result received from sign
  /// up resend code call and say what need to be done next. It choose the right [AuthSignUpStatus]
  Future<AuthSignUpResult> _handleSignUpCodeResult(ResendSignUpCodeResult result) async =>
      // ResendSignUpCodeResult only contains details about where code has been re-sent,
      // therefore we suppose everything went fine in the absence of any exception,
      // that is user has been sent a new code he/she must provide now.
      AuthSignUpResult(
        status: AuthSignUpStatus.confirmSignUpWithCode,
        extra: result.codeDeliveryDetails,
      );

  /// This parses the received error to a [AuthSignUpStatus]
  static AuthSignUpStatus _parseException(AuthException exception) => switch (exception) {
        AliasExistsException _ =>
          // This error fires when user pool is configured as username-centric and when
          // chosen email is already used in another account. Untested, colliding phone
          // numbers likely also generate this exception.
          // Note that Cognito unfortunately checks attributes collision upon signup confirmation,
          // that is after account creation which leads to complicated troubles:
          //
          // - attempting to sign up again with same new username and another email address fails
          //   with UsernameExistsException.
          // - attempting to sign-in results in a signupConfirmation required, which again fails
          //
          // We therefore better like to create Cognito user poll email-centric,
          // which enables email collision detection upon signup, before account creation.
          //
          // Message example: "An account with the email already exists."
          // (no recovery suggestion)
          AuthSignUpStatus.accountPropertyConflict,
        CodeMismatchException _ =>
          // Message example: "Invalid verification code provided, please try again"
          // (no recovery suggestion)
          AuthSignUpStatus.wrongConfirmationCode,
        ExpiredCodeException _ =>
          // Note that a confirmation code posted with a wrong accountId also generate this error.
          // Message example: "Invalid code provided, please request a code again."
          // (no recovery suggestion)
          AuthSignUpStatus.sessionExpired,
        InvalidParameterException _ =>
          // At least one provided form field is malformed
          // Message example: "1 validation error detected: ... (detail)"
          // (no recovery suggestion)
          AuthSignUpStatus.badArgument,
        InvalidPasswordException _ =>
          // Message example: "Password did not conform with policy: Password not long enough"
          // (no recovery suggestion)
          AuthSignUpStatus.passwordNotConform,
        NetworkException _ =>
          // Message example: "The request failed due to a network error."
          // Recovery suggestion example: "Ensure that you have an active network connection"
          AuthSignUpStatus.networkError,
        NotAuthorizedServiceException _ =>
          // ex: "SignUp is not permitted for this user pool"
          // (no recovery suggestion)
          AuthSignUpStatus.genericError,
        UsernameExistsException _ =>
          // User ID (account name or email depending on user pool configuration) already exists.
          // ex: "User already exists"
          // (no recovery suggestion)
          AuthSignUpStatus.accountIdentifierConflict,
        _ => AuthSignUpStatus.genericError,
      };
}
