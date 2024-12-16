// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This service manages the Cognito Sign in methods
class CognitoSignInService extends AbstractService {
  /// This message is displayed in the exception message received when a sign in session is expired.
  /// This may happen, if you take too much time to update your password for confirmation after
  /// sign in
  static const _sessionExpiredMessage = "session is expired";

  /// This is the Cognito service logs helper
  final LogsHelper logsHelper;

  /// Class constructor
  CognitoSignInService({
    required this.logsHelper,
  }) : super();

  /// Service init method
  @override
  Future<void> initService() async {}

  /// Sign the user in the application
  ///
  /// If an exception has to be managed particularly, do it in [_parseException]
  Future<AuthSignInResult> signInUser({
    required String username,
    required String password,
  }) async {
    SignInResult amplifyResult;
    try {
      amplifyResult = await Amplify.Auth.signIn(
        username: username,
        password: password,
      );
    } on AuthException catch (e) {
      logsHelper.e('Error sign in: ${e.message}');
      return AuthSignInResult(status: _parseException(e), extra: e);
    }

    return _handleSignInResult(amplifyResult);
  }

  /// This method allows to confirm the sign in.
  /// In case, an admin creates an user with a temporary password, this method is used to send the
  /// new password.
  ///
  /// If an exception has to be managed particularly, do it in [_parseException]
  Future<AuthSignInResult> confirmSignIn({
    required String confirmationValue,
  }) async {
    SignInResult? amplifyResult;
    try {
      amplifyResult = await Amplify.Auth.confirmSignIn(
        confirmationValue: confirmationValue,
      );
    } on AuthException catch (e) {
      logsHelper.e('Error sign in confirmation: ${e.message}');
      return AuthSignInResult(status: _parseException(e), extra: e);
    }

    return _handleSignInResult(amplifyResult);
  }

  /// Log out the user from the application
  Future<bool> signOut() async {
    final amplifyResult = await Amplify.Auth.signOut();

    return amplifyResult is CognitoCompleteSignOut;
  }

  /// The sign in process can be in several steps, this method parses the result received from sign
  /// in result and say what need to be done next. It choose the right [AuthSignInStatus]
  Future<AuthSignInResult> _handleSignInResult(SignInResult result) async {
    AuthSignInResult actResult;

    switch (result.nextStep.signInStep) {
      case AuthSignInStep.confirmSignInWithSmsMfaCode:
        logsHelper.d("Confirm sign in with SMS MFA code needed");
        actResult = const AuthSignInResult(status: AuthSignInStatus.notSupportedYet);
        break;
      case AuthSignInStep.confirmSignInWithTotpMfaCode:
        logsHelper.d("Confirm sign in with TOTP MFA code needed");
        actResult = const AuthSignInResult(status: AuthSignInStatus.notSupportedYet);
        break;
      case AuthSignInStep.continueSignInWithMfaSelection:
        logsHelper.d("Continue sign in with MFA selection");
        actResult = const AuthSignInResult(status: AuthSignInStatus.notSupportedYet);
        break;
      case AuthSignInStep.continueSignInWithTotpSetup:
        logsHelper.d("Continue sign in with TOTP setup");
        actResult = const AuthSignInResult(status: AuthSignInStatus.notSupportedYet);
        break;
      case AuthSignInStep.confirmSignInWithCustomChallenge:
        logsHelper.d("Confirm sign in with custom challenge needed");
        actResult = const AuthSignInResult(status: AuthSignInStatus.notSupportedYet);
        break;
      case AuthSignInStep.confirmSignInWithNewPassword:
        logsHelper.d("Enter a new password to continue signing in");
        actResult = const AuthSignInResult(status: AuthSignInStatus.confirmSignInWithNewPassword);
        break;
      case AuthSignInStep.resetPassword:
        logsHelper.d("Need to reset password");
        actResult = const AuthSignInResult(status: AuthSignInStatus.resetPassword);
        break;
      case AuthSignInStep.confirmSignUp:
        logsHelper.d("Need to confirm sign up");
        actResult = const AuthSignInResult(status: AuthSignInStatus.confirmSignUp);
        break;
      case AuthSignInStep.done:
        logsHelper.d("Sign in is complete");
        actResult = const AuthSignInResult(status: AuthSignInStatus.done);
        break;
    }

    return actResult;
  }

  /// This parses the received error to a [AuthSignInStatus]
  static AuthSignInStatus _parseException(AuthException exception) {
    if (exception is NetworkException) {
      return AuthSignInStatus.networkError;
    }

    if (exception is NotAuthorizedServiceException) {
      if (exception.message.contains(_sessionExpiredMessage)) {
        return AuthSignInStatus.sessionExpired;
      }

      return AuthSignInStatus.wrongUsernameOrPwd;
    }

    if (exception is InvalidPasswordException) {
      return AuthSignInStatus.newPasswordNotConform;
    }

    return AuthSignInStatus.genericError;
  }
}
