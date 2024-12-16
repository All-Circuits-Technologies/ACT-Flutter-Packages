// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

enum AuthSignUpStatus {
  /// An argument, optional on generic services API but mandatory for effective service, is missing
  ///
  /// This can be the result of [MixinAuthService.signUp] if called without email despite
  /// a concrete service requiring it.
  missingArgument,

  /// At least one argument is insane
  ///
  /// Ex: an empty string is provided where a non-empty value is obviously required.
  badArgument,

  /// The sign-up is not complete, a verification code has been sent to user and must be inputted
  ///
  /// This is likely the result of [MixinAuthService.signUp], requiring a subsequent call
  /// to [MixinAuthService.confirmSignUp]
  confirmSignUpWithCode(isSuccess: true, userNeedsToAct: true),

  /// Another account already exists with same account identifier
  ///
  /// This is likely the result of [MixinAuthService.signUp]
  accountIdentifierConflict(userNeedsToAct: true),

  /// Another account already exists with same email, phone or other globally unique attribute
  ///
  /// This is likely the result of [MixinAuthService.signUp] but can also be the result of
  /// [MixinAuthService.confirmSignUp] for services verifying those collisions lazily.
  accountPropertyConflict(userNeedsToAct: true),

  /// Sign-up attempt is rejected due to weak chosen password
  ///
  /// This can be the result of [MixinAuthService.signUp].
  /// If service does not support accurate error distinction, [badArgument] may be fired instead.
  passwordNotConform(userNeedsToAct: true),

  /// The sign-up is complete.
  ///
  /// This is likely the result of [MixinAuthService.confirmSignUp],
  /// but may also be the result of [MixinAuthService.signUp] if no confirmations are needed
  done(isSuccess: true),

  /// The sign up session has expired, you likely need to resend a confirmation code
  ///
  /// This can be the result of [MixinAuthService.confirmSignUp] if code has expired,
  /// requiring a subsequent call to [MixinAuthService.resendSignUpCode].
  ///
  /// This can also be the result of a [MixinAuthService.confirmSignUp] called with an bad account
  /// identifier (bad call) or targeting an account just recently confirmed (code already used).
  sessionExpired,

  /// Provided confirmation code is rejected
  ///
  /// This can be the result of [MixinAuthService.confirmSignUp] if user made a typo error
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
  const AuthSignUpStatus({
    this.isSuccess = false,
    this.userNeedsToAct = false,
  });
}
