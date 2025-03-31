// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This service manages the password mechanisms such as: update, reset password, etc.
class CognitoPasswordService extends AbsWithLifeCycle {
  /// This is the Cognito service logs helper
  final LogsHelper logsHelper;

  /// Class constructor
  CognitoPasswordService({
    required this.logsHelper,
  }) : super();

  /// This method fires the password resets. A confirmation code should be sent.
  ///
  /// If an exception has to be managed particularly, do it in [_parseException]
  Future<AuthResetPwdResult> resetPassword({
    required String username,
  }) async {
    ResetPasswordResult result;
    try {
      result = await Amplify.Auth.resetPassword(
        username: username,
      );
    } on AuthException catch (e) {
      logsHelper.e('Error resetting password: ${e.message}');
      return AuthResetPwdResult(status: _parseException(e), extra: e);
    }

    if (result.isPasswordReset) {
      logsHelper.w("We ask for password reset but we aren't in the right step (it said that "
          "everything is done)");
      return const AuthResetPwdResult(status: AuthResetPwdStatus.genericError);
    }

    return const AuthResetPwdResult(status: AuthResetPwdStatus.done);
  }

  /// Confirm the password resetting. The [confirmationCode] is the one received by mail, SMS, etc.
  ///
  /// If an exception has to be managed particularly, do it in [_parseException]
  Future<AuthResetPwdResult> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async {
    ResetPasswordResult result;
    try {
      result = await Amplify.Auth.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );
    } on AuthException catch (e) {
      logsHelper.e('Error resetting password: ${e.message}');
      return AuthResetPwdResult(status: _parseException(e), extra: e);
    }

    if (!result.isPasswordReset) {
      logsHelper.w("We try to confirm the password resetting but it hasn't been acknowledged: "
          "$result");
      return const AuthResetPwdResult(status: AuthResetPwdStatus.genericError);
    }

    return const AuthResetPwdResult(status: AuthResetPwdStatus.done);
  }

  /// Allows to update the user password.
  ///
  /// An user must be connected to call this method.
  ///
  /// If an exception has to be managed particularly, do it in [_parseException]
  Future<AuthResetPwdResult> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await Amplify.Auth.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
    } on AuthException catch (e) {
      logsHelper.e('Error updating password: ${e.message}');
      return AuthResetPwdResult(status: _parseException(e), extra: e);
    }

    return const AuthResetPwdResult(status: AuthResetPwdStatus.done);
  }

  /// This parses the received error to a [AuthResetPwdStatus]
  static AuthResetPwdStatus _parseException(AuthException exception) => switch (exception) {
        CodeMismatchException _ => AuthResetPwdStatus.wrongConfirmationCode,
        InvalidPasswordException _ => AuthResetPwdStatus.newPasswordNotConform,
        NetworkException _ => AuthResetPwdStatus.networkError,
        NotAuthorizedServiceException _ => AuthResetPwdStatus.wrongUsernameOrPwd,
        _ => AuthResetPwdStatus.genericError,
      };
}
