// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This is the status of reset password methods
enum AuthResetPwdStatus {
  /// That error means the password resetting must be confirmed by a code sent
  /// Therefore, a view must shown and the confirm reset method has to be called.
  confirmResetPasswordWithCode(userNeedsToAct: true),

  /// This means that everything has worked as expected
  done(isSuccess: true),

  /// This means that what we wanted is not yet supported by our packages and need more development
  notSupportedYet(isError: true),

  /// Represents a network problem such as: the phone is no more connected to internet
  networkError(isError: true),

  /// Request is unauthorized, likely due to a wrong credential in the request
  ///
  /// Likely current password is wrong during a password update procedure
  wrongUsernameOrPwd(isError: true),

  /// Confirmation code or MFA is wrong
  wrongConfirmationCode(isError: true),

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
  const AuthResetPwdStatus({
    this.isSuccess = false,
    this.userNeedsToAct = false,
    this.isError = false,
  });
}
