// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_amplify_cognito/src/cognito_delete_service.dart';
import 'package:act_amplify_cognito/src/cognito_password_service.dart';
import 'package:act_amplify_cognito/src/cognito_sign_in_service.dart';
import 'package:act_amplify_cognito/src/cognito_sign_up_service.dart';
import 'package:act_amplify_cognito/src/cognito_user_service.dart';
import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';

/// This is the Cognito Amplify service which implements the [MixinAuthService].
///
/// This Cognito service regroups multiple services linked.
class AmplifyCognitoService extends AbsAmplifyService with MixinAuthService {
  /// Logs category for cognito service
  static const _logsCategory = "cognito";

  /// The service logs helper
  late final LogsHelper _logsHelper;

  /// This service manages all the sign up methods
  late final CognitoSignUpService _signUpService;

  /// This service manages all the sign in methods
  late final CognitoSignInService _signInService;

  /// This service manages all the password mechanisms (update, reset, etc.)
  late final CognitoPasswordService _pwdService;

  /// This service manages the user getting and setting from Cognito
  late final CognitoUserService _userService;

  /// This service manages account deletion
  late final CognitoDeleteService _deleteService;

  /// This stream controller sends event when the [AuthStatus] change
  final StreamController<AuthStatus> _authStatusCtrl;

  /// This contains the list of all the subscriptions done in the service
  final List<StreamSubscription> _cognitoStreamSubs;

  /// The current [AuthStatus]
  AuthStatus _authStatus;

  /// Get the stream linked to the [AuthStatus] current value
  @override
  Stream<AuthStatus> get authStatusStream => _authStatusCtrl.stream;

  /// Get the current [AuthStatus] value
  @override
  AuthStatus get authStatus => _authStatus;

  /// Class constructor
  AmplifyCognitoService()
      : _authStatus = AuthStatus.signedOut,
        _authStatusCtrl = StreamController.broadcast(),
        _cognitoStreamSubs = [],
        super();

  /// Init the service
  ///
  /// Don't forget to create and init the children services here
  @override
  Future<void> initLifeCycle({
    LogsHelper? parentLogsHelper,
  }) async {
    await super.initLifeCycle();
    _logsHelper = AbsAmplifyService.createLogsHelper(
      logCategory: _logsCategory,
      parentLogsHelper: parentLogsHelper,
    );

    // Listen on Amplify Auth Hub event to get the known information
    _cognitoStreamSubs.add(Amplify.Hub.listen<AuthUser, AuthHubEvent>(
      HubChannel.Auth,
      _onAuthEvent,
    ));

    _signUpService = CognitoSignUpService(logsHelper: _logsHelper);
    _signInService = CognitoSignInService(logsHelper: _logsHelper);
    _pwdService = CognitoPasswordService(logsHelper: _logsHelper);
    _userService = CognitoUserService(logsHelper: _logsHelper);
    _deleteService = CognitoDeleteService(logsHelper: _logsHelper);

    // Because the services are independents between each others, we init them in parallel
    await Future.wait([
      _signUpService.initLifeCycle(),
      _signInService.initLifeCycle(),
      _pwdService.initLifeCycle(),
      _userService.initLifeCycle(),
      _deleteService.initLifeCycle(),
    ]);

    // If the user is currently signed in we set the status in [_authStatus]
    if (await _userService.isUserSigned()) {
      _authStatus = AuthStatus.signedIn;
    }
  }

  /// Called when a new [AuthHubEvent] is detected by Amplify (because the user signed in, log out,
  /// etc.)
  void _onAuthEvent(AuthHubEvent event) {
    switch (event.type) {
      case AuthHubEventType.signedIn:
        _logsHelper.i('User is signed in.');
        _setAuthStatus(AuthStatus.signedIn);
        break;
      case AuthHubEventType.signedOut:
        _logsHelper.i('User is signed out.');
        _setAuthStatus(AuthStatus.signedOut);
        break;
      case AuthHubEventType.sessionExpired:
        _logsHelper.i('The session has expired.');
        _setAuthStatus(AuthStatus.sessionExpired);
        break;
      case AuthHubEventType.userDeleted:
        _logsHelper.i('The user has been deleted.');
        _setAuthStatus(AuthStatus.userDeleted);
        break;
    }
  }

  /// Get the current session of the user
  Future<CognitoAuthSession> getAwsAuthSession() async =>
      Amplify.Auth.getPlugin(AmplifyAuthCognito.pluginKey).fetchAuthSession(
        options: const FetchAuthSessionOptions(forceRefresh: true),
      );

  /// Sign an url with the AWS signature V4
  Uri signUrl({
    required AWSCredentials creds,
    required AWSService service,
    required String region,
    required String endpoint,
    required Duration signerValidityDuration,
    required String urlPath,
    required String scheme,
  }) {
    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(creds),
    );

    final scope = AWSCredentialScope(
      region: region,
      service: service,
    );

    final request = AWSHttpRequest(
      method: AWSHttpMethod.get,
      uri: Uri.https(endpoint, urlPath),
    );

    final serviceConfiguration = const BaseServiceConfiguration(
      omitSessionToken: true,
    );

    final signed = signer.presignSync(
      request,
      credentialScope: scope,
      expiresIn: signerValidityDuration,
      serviceConfiguration: serviceConfiguration,
    );

    return signed.replace(scheme: scheme);
  }

  /// To call in order to the set the [AuthStatus] and send an event to the [AuthStatus] stream
  void _setAuthStatus(AuthStatus value) {
    if (value == _authStatus) {
      // Nothing to do
      return;
    }

    _logsHelper.d("New auth value: $value");
    _authStatus = value;
    _authStatusCtrl.add(value);
  }

  /// Most of the time, we don't need to pass particular configuration to the plugin (all is done on
  /// the server). But, if needed, this method can be overridden by a derived class in the project
  /// if needed to set a particular configuration to the plugin.
  @override
  Future<List<AmplifyPluginInterface>> getLinkedPluginsList() async => [AmplifyAuthCognito()];

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
  @override
  Future<AuthSignUpResult> signUp({
    required String accountId,
    required String password,
    String? email,
  }) =>
      _signUpService.signUp(accountId: accountId, password: password, email: email);

  /// User self-registration second half
  ///
  /// [signUp] self-registration may require user to input a code received by mail or phone.
  /// This is the purpose of this method.
  ///
  /// [accountId] identifies account to confirm.
  /// [code] is the code sent to user by [signUp] procedure (likely into its mailbox)
  @override
  Future<AuthSignUpResult> confirmSignUp({
    required String accountId,
    required String code,
  }) =>
      _signUpService.confirmSignUp(
        accountId: accountId,
        code: code,
      );

  /// Re-ask a sign-up confirmation code
  ///
  /// Confirmation code sent by [signUp] may not have reached its destination.
  /// This method can cope with a transient delivery failure by resending a code.
  ///
  /// [accountId] identifies account to confirm. Some services may also accept user email or phone.
  @override
  Future<AuthSignUpResult> resendSignUpCode({
    required String accountId,
  }) =>
      _signUpService.resendSignUpCode(accountId: accountId);

  /// Sign the user in the application
  @override
  Future<AuthSignInResult> signInUser({
    required String username,
    required String password,
  }) async =>
      _signInService.signInUser(
        username: username,
        password: password,
      );

  /// Log out the user from the application
  @override
  Future<bool> signOut() => _signInService.signOut();

  /// Test if an user is signed to the app (or not)
  @override
  Future<bool> isUserSigned() => _userService.isUserSigned();

  /// {@macro CognitoUserService.getCurrentUserId}
  ///
  /// By default, we don't include the region in the returned id
  @override
  Future<String?> getCurrentUserId() => _userService.getCurrentUserId(
        includeRegion: false,
      );

  /// Get the access token of the logged user
  ///
  /// Return null if no user is logged or if a problem occurred
  @override
  Future<AuthTokens?> getTokens() => _userService.getTokens();

  /// This method allows to confirm the sign in.
  /// In case, an admin creates an user with a temporary password, this method is used to send the
  /// new password.
  @override
  Future<AuthSignInResult> confirmSignIn({
    required String confirmationValue,
  }) async =>
      _signInService.confirmSignIn(confirmationValue: confirmationValue);

  /// This method fires the password resets. A confirmation code should be sent.
  @override
  Future<AuthResetPwdResult> resetPassword({
    required String username,
  }) async =>
      _pwdService.resetPassword(username: username);

  /// Confirm the password resetting. The [confirmationCode] is the one received by mail, SMS, etc.
  @override
  Future<AuthResetPwdResult> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async =>
      _pwdService.confirmResetPassword(
        username: username,
        newPassword: newPassword,
        confirmationCode: confirmationCode,
      );

  /// Allows to update the user password.
  ///
  /// An user must be connected to call this method.
  @override
  Future<AuthResetPwdResult> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async =>
      _pwdService.updatePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

  /// Get email address of currently logged user
  ///
  /// A user must be connected to call this method.
  /// Returns null if no users are logged in, if account has no known emails (unlikely)
  /// or if a problem occurred
  @override
  Future<String?> getEmailAddress() async => _userService.getEmailAddress();

  /// Change email address of currently logged user
  ///
  /// A user must be connected to call this method.
  /// [address] should be a valid email address.
  @override
  Future<AuthPropertyResult> setEmailAddress(String address) async =>
      _userService.setEmailAddress(address);

  /// Confirm email address change of currently logged user
  ///
  /// A user must be connected to call this method.
  /// You may need to call this method after [setEmailAddress] depending on its result.
  @override
  Future<AuthPropertyResult> confirmEmailAddressUpdate({required String code}) async =>
      _userService.confirmEmailAddressUpdate(code: code);

  /// Delete currently logged-in account
  ///
  /// A user must be connected to call this method.
  @override
  Future<AuthDeleteResult> deleteAccount() async => _deleteService.deleteAccount();

  /// Return known cognito exceptions announcing non transient authentication issues
  ///
  /// An app may want to show user a sign in page when it catches one of those exceptions somewhere.
  Set<Type> getNonTransientAuthFailureTypes() => {
        UserNotFoundException,
        SignedOutException,
      };

  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait([
      _signUpService.disposeLifeCycle(),
      _signInService.disposeLifeCycle(),
      _pwdService.disposeLifeCycle(),
      _userService.disposeLifeCycle(),
      _deleteService.disposeLifeCycle(),
    ]);

    final subsFuture = <Future>[];
    for (final sub in _cognitoStreamSubs) {
      subsFuture.add(sub.cancel());
    }

    await Future.wait(subsFuture);

    await _authStatusCtrl.close();
    await super.disposeLifeCycle();
  }
}
