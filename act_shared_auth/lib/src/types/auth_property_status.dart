// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Possible result status property requests can return
enum AuthPropertyStatus {
  /// At least one argument is insane
  ///
  /// Ex: an email not looking like an email
  badArgument,

  /// The request is not complete, a verification code has been sent to user and must be inputted
  ///
  /// This is likely the result of `MixinAuthService.setEmailAddress`, requiring a subsequent call
  /// to `MixinAuthService.confirmEmailAddressUpdate`
  confirmWithCode(isSuccess: true, userNeedsToAct: true),

  /// Another account already exists with same value for this property, configured as unique
  ///
  /// This is likely the result of `MixinAuthService.setEmailAddress` or
  /// `MixinAuthService.confirmEmailAddressUpdate`
  accountPropertyConflict(userNeedsToAct: true),

  /// The request is complete.
  ///
  /// This is likely the result of `MixinAuthService.confirmEmailAddressUpdate`, but may also be
  /// the result of `MixinAuthService.setEmailAddress` if no confirmations are needed
  done(isSuccess: true),

  /// The session has expired, you likely need to resend a confirmation code
  ///
  /// This can be the result of `MixinAuthService.confirmEmailAddressUpdate` if code has expired,
  /// requiring a subsequent call to `MixinAuthService.confirmEmailAddressUpdate`.
  sessionExpired,

  /// Provided confirmation code is rejected
  ///
  /// This can be the result of `MixinAuthService.confirmEmailAddressUpdate` if user made an error
  wrongConfirmationCode(userNeedsToAct: true),

  /// This means that what we wanted is not yet supported by our packages and need more development
  notSupportedYet,

  /// Represents a network problem such as: the phone is no more connected to internet
  networkError,

  /// This a generic error
  genericError;

  /// The status represents a success
  final bool isSuccess;

  /// The status represents an error
  bool get isError => !isSuccess;

  /// An action is needed on user-side
  ///
  /// This can be either a subsequent required action after succeed action (ex: confirm code),
  /// or an error clearly related to the user for which the user can try again (ex: wrong code).
  final bool userNeedsToAct;

  /// Class constructor
  const AuthPropertyStatus({
    this.isSuccess = false,
    this.userNeedsToAct = false,
  });
}
