// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_amplify_cognito/src/cognito_password_service.dart';
import 'package:act_amplify_cognito/src/cognito_sign_in_service.dart';
import 'package:act_amplify_cognito/src/cognito_user_service.dart';
import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

/// This is the Cognito Amplify service which implements the [MixinAuthService].
///
/// This Cognito service regroups multiple services linked
class AmplifyCognitoService extends AbsAmplifyService with MixinAuthService {
  /// Logs category for cognito service
  static const _logsCategory = "cognito";

  /// The service logs helper
  late final LogsHelper _logsHelper;

  /// This service manages all the sign in methods
  late final CognitoSignInService _signInService;

  /// This service manages all the password mechanisms (update, reset, etc.)
  late final CognitoPasswordService _pwdService;

  /// This service manages the user getting and setting from Cognito
  late final CognitoUserService _userService;

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
  Future<void> initService({
    required LogsHelper parentLogsHelper,
  }) async {
    _logsHelper = parentLogsHelper.createASubLogsHelper(_logsCategory);

    // Listen on Amplify Auth Hub event to get the known information
    _cognitoStreamSubs.add(Amplify.Hub.listen<AuthUser, AuthHubEvent>(
      HubChannel.Auth,
      _onAuthEvent,
    ));

    _signInService = CognitoSignInService(logsHelper: _logsHelper);
    _pwdService = CognitoPasswordService(logsHelper: _logsHelper);
    _userService = CognitoUserService(logsHelper: _logsHelper);

    // Because the services are independents between each others, we init them in parallel
    await Future.wait([
      _signInService.initService(),
      _pwdService.initService(),
      _userService.initService(),
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

  @override
  Future<void> dispose() async {
    await super.dispose();

    await Future.wait([
      _signInService.dispose(),
      _pwdService.dispose(),
      _userService.dispose(),
    ]);

    final subsFuture = <Future>[];
    for (final sub in _cognitoStreamSubs) {
      subsFuture.add(sub.cancel());
    }

    await Future.wait(subsFuture);

    await _authStatusCtrl.close();
  }
}
