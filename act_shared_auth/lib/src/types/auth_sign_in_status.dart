// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This is the sign in authentication status
enum AuthSignInStatus {
  /// The sign-in is not complete and must be confirmed with the user's new password.
  confirmSignInWithNewPassword(userNeedsToAct: true),

  /// The sign-in is not complete and the user must reset their password before proceeding.
  resetPassword(userNeedsToAct: true),

  /// The sign-in is not complete and the user's sign up must be confirmed before proceeding.
  confirmSignUp(userNeedsToAct: true),

  /// The sign-in is complete.
  done(isSuccess: true),

  /// This means that what we wanted is not yet supported by our packages and need more development
  notSupportedYet(isError: true),

  /// Represents a network problem such as: the phone is no more connected to internet
  networkError(isError: true),

  /// The sign in session has expired and you need to sign in the app again
  sessionExpired(isError: true),

  /// The username and/or password the user gave isn't right
  wrongUsernameOrPwd(isError: true),

  /// This means that the new chosen password doesn't match the requirements imposed by the server
  newPasswordNotConform(isError: true),

  /// This a generic error
  genericError(isError: true);

  /// The status represents a success
  final bool isSuccess;

  /// The status represents an error
  final bool isError;

  /// The status represents an action to do by the user
  final bool userNeedsToAct;

  /// Class constructor
  const AuthSignInStatus({
    this.isSuccess = false,
    this.userNeedsToAct = false,
    this.isError = false,
  });
}
