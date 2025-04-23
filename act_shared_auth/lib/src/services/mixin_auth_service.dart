// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_shared_auth/act_shared_auth.dart';

/// This mixin has to be used by third party package when implementing shared authentication.
mixin MixinAuthService {
  /// {@template act_shared_auth.MixinAuthService.signUp}
  /// User self-registration entry-point
  ///
  /// Depending on service, [accountId] is either an account identifier or an email address.
  /// It must be chosen uniquely among all accounts.
  ///
  /// [password] must match service requirements.
  ///
  /// [email] is often required by services as an anti-robot feature. Service may sent it a code
  /// to ensure user own this email address, in such case a subsequent call to [confirmSignUp]
  /// is required to complete account sign-up. Services requiring an email address for [accountId]
  /// will likely ignore this parameter or can just test it against [accountId] if provided.
  ///
  /// You are advised to read method implementation documentation for service-specific details.
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<AuthSignUpResult> signUp({
    required String accountId,
    required String password,
    String? email,
  }) =>
      _crashUnimplemented("signUp");

  /// {@template act_shared_auth.MixinAuthService.confirmSignUp}
  /// User self-registration second half
  ///
  /// [signUp] self-registration may require user to input a code received by mail or by phone.
  /// This is the purpose of this method.
  ///
  /// [accountId] identifies account to confirm. Some services may also accept user email or phone.
  /// [code] is the code sent to user by [signUp] procedure (likely into its mailbox)
  ///
  /// You are advised to read method implementation documentation for service-specific details.
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<AuthSignUpResult> confirmSignUp({
    required String accountId,
    required String code,
  }) =>
      _crashUnimplemented("confirmSignUp");

  /// {@template act_shared_auth.MixinAuthService.resendSignUpCode}
  /// Re-ask a sign-up confirmation code
  ///
  /// Confirmation code sent by [signUp] may not have reached its destination.
  /// This method can cope with a transient delivery failure by resending a code.
  ///
  /// [accountId] identifies account to confirm. Some services may also accept user email or phone.
  ///
  /// You are advised to read method implementation documentation for service-specific details.
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<AuthSignUpResult> resendSignUpCode({
    required String accountId,
  }) =>
      _crashUnimplemented("resendSignUpCode");

  /// {@template act_shared_auth.MixinAuthService.authStatusStream}
  /// This stream emits [AuthStatus] update
  /// {@endtemplate}
  Stream<AuthStatus> get authStatusStream;

  /// {@template act_shared_auth.MixinAuthService.authStatus}
  /// This is the current [AuthStatus]
  /// {@endtemplate}
  AuthStatus get authStatus;

  /// {@template act_shared_auth.MixinAuthService.signInUser}
  /// Sign the user in the application
  ///
  /// [username] may also be an user email or anything else accepted as username by your third party
  /// service
  /// {@endtemplate}
  Future<AuthSignInResult> signInUser({
    required String username,
    required String password,
  });

  /// {@template act_shared_auth.MixinAuthService.signOut}
  /// Log out the user from the application
  /// {@endtemplate}
  Future<bool> signOut();

  /// {@template act_shared_auth.MixinAuthService.isUserSigned}
  /// Test if an user is signed to the app (or not)
  /// {@endtemplate}
  Future<bool> isUserSigned();

  /// {@template act_shared_auth.MixinAuthService.getCurrentUserId}
  /// Get the current user id
  ///
  /// Return null if no user is logged or if a problem occurred
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<String?> getCurrentUserId() async => _crashUnimplemented("getUserCurrentId");

  /// {@template act_shared_auth.MixinAuthService.getAccessToken}
  /// Get the access token of the logged user
  ///
  /// Return null if no user is logged or if a problem occurred
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<String?> getAccessToken() async => _crashUnimplemented("getAccessToken");

  /// {@template act_shared_auth.MixinAuthService.confirmSignIn}
  /// This method allows to confirm the sign in.
  /// In case, an admin creates an user with a temporary password, this method is used to send the
  /// new password.
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<AuthSignInResult> confirmSignIn({
    required String confirmationValue,
  }) async =>
      _crashUnimplemented("confirmSignIn");

  /// {@template act_shared_auth.MixinAuthService.resetPassword}
  /// This method fires the password resets. A confirmation code could be sent.
  ///
  /// [username] may also be an user email or anything else accepted as username by your third party
  /// service
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<AuthResetPwdResult> resetPassword({
    required String username,
  }) async =>
      _crashUnimplemented("resetPassword");

  /// {@template act_shared_auth.MixinAuthService.confirmResetPassword}
  /// Confirm the password resetting. The [confirmationCode] is the one received by mail, SMS, etc.
  ///
  /// [username] may also be an user email or anything else accepted as username by your third party
  /// service
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<AuthResetPwdResult> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async =>
      _crashUnimplemented("confirmResetPassword");

  /// {@template act_shared_auth.MixinAuthService.updatePassword}
  /// Allows to update the user password.
  ///
  /// An user must be connected to call this method.
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<AuthResetPwdResult> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async =>
      _crashUnimplemented("updatePassword");

  /// {@template act_shared_auth.MixinAuthService.getEmailAddress}
  /// Get email address of currently logged user
  ///
  /// A user must be connected to call this method.
  /// Returns null if no users are logged in, if account has no known emails (unlikely)
  /// or if a problem occurred
  /// {@endtemplate}
  Future<String?> getEmailAddress() async => _crashUnimplemented("getEmailAddress");

  /// {@template act_shared_auth.MixinAuthService.setEmailAddress}
  /// Change email address of currently logged user
  ///
  /// A user must be connected to call this method.
  /// [address] should be a valid email address.
  /// {@endtemplate}
  Future<AuthPropertyResult> setEmailAddress(String address) async =>
      _crashUnimplemented("setEmailAddress");

  /// {@template act_shared_auth.MixinAuthService.confirmEmailAddressUpdate}
  /// Confirm email address change of currently logged user
  ///
  /// A user must be connected to call this method.
  /// You may need to call this method after [setEmailAddress] depending on its result.
  /// {@endtemplate}
  Future<AuthPropertyResult> confirmEmailAddressUpdate({required String code}) async =>
      _crashUnimplemented("confirmEmailAddressUpdate");

  /// {@template act_shared_auth.MixinAuthService.deleteAccount}
  /// Delete currently logged-in account
  ///
  /// A user must be connected to call this method.
  ///
  /// DO NOT USE THIS METHOD IF THE THIRD PARTY PACKAGE SERVICE DOESN'T OVERRIDE IT
  /// {@endtemplate}
  Future<AuthDeleteResult> deleteAccount() async => _crashUnimplemented("deleteAccount");

  /// This trap forcibly crashes the app when unsupported methods are reached
  ///
  /// Service either misses this method implementation or it does not support it at all.
  /// If a service can support missing method but do not implement it yet, developer may want to
  /// implement it and return notSupportedYet error (which exists in all auth statuses).
  Never _crashUnimplemented(String method) {
    final err = "$runtimeType service does not implement $method";
    assert(false, err);
    throw Exception(err);
  }
}
