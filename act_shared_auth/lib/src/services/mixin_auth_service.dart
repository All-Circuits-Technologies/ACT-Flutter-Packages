// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';

/// This mixin has to be used by third party package when implementing shared authentication.
mixin MixinAuthService {
  /// This stream emits [AuthStatus] update
  Stream<AuthStatus> get authStatusStream;

  /// This is the current [AuthStatus]
  AuthStatus get authStatus;

  /// Sign the user in the application
  ///
  /// [username] may also be an user email or anything else accepted as username by your third party
  /// service
  Future<AuthSignInResult> signInUser({
    required String username,
    required String password,
  });

  /// Log out the user from the application
  Future<bool> signOut();

  /// Test if an user is signed to the app (or not)
  Future<bool> isUserSigned();

  /// This method allows to confirm the sign in.
  /// In case, an admin creates an user with a temporary password, this method is used to send the
  /// new password.
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  Future<AuthSignInResult> confirmSignIn({
    required String confirmationValue,
  }) async {
    assert(false, "The sign in confirmation method hasn't been implemented");
    throw Exception("The sign in confirmation method hasn't been implemented");
  }

  /// This method fires the password resets. A confirmation code could be sent.
  ///
  /// [username] may also be an user email or anything else accepted as username by your third party
  /// service
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  Future<AuthResetPwdResult> resetPassword({
    required String username,
  }) async {
    assert(false, "The reset password method hasn't been implemented");
    throw Exception("The reset password method hasn't been implemented");
  }

  /// Confirm the password resetting. The [confirmationCode] is the one received by mail, SMS, etc.
  ///
  /// [username] may also be an user email or anything else accepted as username by your third party
  /// service
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  Future<AuthResetPwdResult> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async {
    assert(false,
        "The reset password confirmation method hasn't been implemented");
    throw Exception(
        "The reset password confirmation method hasn't been implemented");
  }

  /// Allows to update the user password.
  ///
  /// An user must be connected to call this method.
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  Future<AuthResetPwdResult> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    assert(false, "The update password method hasn't been implemented");
    throw Exception("The update password method hasn't been implemented");
  }
}
