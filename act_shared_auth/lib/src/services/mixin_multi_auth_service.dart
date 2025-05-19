// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/foundation.dart';

/// This mixin is helpful to manage multiple providers in the app.
///
/// Even if we only manage one account at the time, the user could connect itself from different
/// provider such as the app native provider or OAuth like Google, Facebook, etc. This class allows
/// to know different provider and let the user chooses the one he wants.
mixin MixinMultiAuthService<P extends Enum> on MixinAuthService, AbsWithLifeCycle {
  /// {@template act_shared_auth.MixinMultiAuthService.providers}
  /// This is the list of the known [providers] which can be used to log user.
  /// {@endtemplate}
  @protected
  Map<P, MixinAuthService> get providers;

  /// {@template act_shared_auth.MixinMultiAuthService.logsHelper}
  /// This is the [logsHelper] used to logs errors
  /// {@endtemplate}
  @protected
  LogsHelper get logsHelper;

  /// This controller is used to emit the auth status event of the selected provider
  final _serviceStatusCtrl = StreamController<AuthStatus>.broadcast();

  /// This is the list of subscription of the authentication stream
  final List<StreamSubscription> _subs = [];

  /// This is the linked authentication storage service
  MixinAuthStorageService? _storageService;

  /// This is the key of the current provider
  P? _currentProviderKey;

  /// {@template act_shared_auth.MixinMultiAuthService.currentProviderKey}
  /// Get the current provider key
  /// {@endtemplate}
  @protected
  P? get currentProviderKey => _currentProviderKey;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _serviceStatusCtrl.stream;

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't get the right auth status");
      return AuthStatus.signedOut;
    }

    return provider.authStatus;
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    await Future.wait(
      providers.entries.map((entry) async {
        final provider = entry.value;
        _subs.add(
          provider.authStatusStream.listen((status) => _onAuthStatusUpdated(entry.key, status)),
        );
      }),
    );
  }

  /// {@template act_shared_auth.MixinMultiAuthService.setCurrentProviderKey}
  /// Set the current provider key
  ///
  /// The method moves the storage service from the old provider to the new one. And clear the ids
  /// and tokens from memory.
  ///
  /// We only the storage service to one provider to be sure that the providers don't access or
  /// remove elements not linked with their processes.
  /// {@endtemplate}
  @protected
  Future<void> setCurrentProviderKey(P? value) async {
    if (_currentProviderKey == value) {
      // Nothing to do
      return;
    }

    final oldKey = _currentProviderKey;
    _currentProviderKey = value;

    if (_storageService == null) {
      // Nothing more to do
      return;
    }

    if (_currentProviderKey != null) {
      final provider = providers[oldKey];
      if (provider != null) {
        await provider.setStorageService(null);
      }

      // Clear storage values
      await _storageService!.clearTokens();
      if (await _storageService!.isUserIdsStorageSupported()) {
        await _storageService!.clearUserIds();
      }
    }

    if (value != null) {
      final provider = providers[value];
      if (provider != null) {
        await provider.setStorageService(_storageService);
      }
    }
  }

  /// {@macro act_shared_auth.MixinAuthService.setStorageService}
  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async {
    if (storageService == _storageService) {
      // Nothing to do
      return;
    }

    _storageService = storageService;
    final provider = _getCurrentProvider();
    if (provider == null) {
      // Nothing to do
      return;
    }

    return provider.setStorageService(storageService);
  }

  /// {@macro act_shared_auth.MixinAuthService.signUp}
  @override
  Future<AuthSignUpResult> signUp({
    required String accountId,
    required String password,
    String? email,
  }) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't sign up the user");
      return const AuthSignUpResult(status: AuthSignUpStatus.genericError);
    }

    return provider.signUp(accountId: accountId, password: password);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmSignUp}
  @override
  Future<AuthSignUpResult> confirmSignUp({required String accountId, required String code}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't confirm the user sign up");
      return const AuthSignUpResult(status: AuthSignUpStatus.genericError);
    }

    return provider.confirmSignUp(accountId: accountId, code: code);
  }

  /// {@macro act_shared_auth.MixinAuthService.resendSignUpCode}
  @override
  Future<AuthSignUpResult> resendSignUpCode({required String accountId}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't resend the sign up code");
      return const AuthSignUpResult(status: AuthSignUpStatus.genericError);
    }

    return provider.resendSignUpCode(accountId: accountId);
  }

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  ///
  /// The service will return an error if no provider has been previously selected or if
  /// [providerKey] is null or not linked to a known provider.
  @override
  Future<AuthSignInResult> signInUser({
    required String username,
    required String password,
    P? providerKey,
  }) async {
    if (providerKey != null) {
      await setCurrentProviderKey(providerKey);
    }

    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't sign in the user");
      return const AuthSignInResult(status: AuthSignInStatus.genericError);
    }

    return provider.signInUser(username: username, password: password);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmSignIn}
  @override
  Future<AuthSignInResult> confirmSignIn({
    required String confirmationValue,
  }) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't confirm the user sign in");
      return const AuthSignInResult(status: AuthSignInStatus.genericError);
    }

    return provider.confirmSignIn(confirmationValue: confirmationValue);
  }

  /// {@macro act_shared_auth.MixinAuthService.redirectToExternalUserSignIn}
  @override
  Future<AuthSignInResult> redirectToExternalUserSignIn({
    P? providerKey,
  }) async {
    if (providerKey != null) {
      await setCurrentProviderKey(providerKey);
    }

    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper
          .w("No provider has been set, we can't redirect sign in to an external user interface");
      return const AuthSignInResult(status: AuthSignInStatus.genericError);
    }

    return provider.redirectToExternalUserSignIn();
  }

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't sign out the user");
      return false;
    }

    return provider.signOut();
  }

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't know if the user is signed or not");
      return false;
    }

    return provider.isUserSigned();
  }

  /// {@macro act_shared_auth.MixinAuthService.getCurrentUserId}
  @override
  Future<String?> getCurrentUserId() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't get the current user id");
      return null;
    }

    return provider.getCurrentUserId();
  }

  /// {@macro act_shared_auth.MixinAuthService.getTokens}
  @override
  Future<AuthTokens?> getTokens() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't get the access token");
      return null;
    }

    return provider.getTokens();
  }

  /// {@macro act_shared_auth.MixinAuthService.resetPassword}
  @override
  Future<AuthResetPwdResult> resetPassword({required String username}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't reset the password");
      return const AuthResetPwdResult(status: AuthResetPwdStatus.genericError);
    }

    return provider.resetPassword(username: username);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmResetPassword}
  @override
  Future<AuthResetPwdResult> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't confirm the password reset");
      return const AuthResetPwdResult(status: AuthResetPwdStatus.genericError);
    }

    return provider.confirmResetPassword(
      username: username,
      newPassword: newPassword,
      confirmationCode: confirmationCode,
    );
  }

  /// {@macro act_shared_auth.MixinAuthService.updatePassword}
  @override
  Future<AuthResetPwdResult> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't update the password");
      return const AuthResetPwdResult(status: AuthResetPwdStatus.genericError);
    }

    return provider.updatePassword(oldPassword: oldPassword, newPassword: newPassword);
  }

  /// {@macro act_shared_auth.MixinAuthService.getEmailAddress}
  @override
  Future<String?> getEmailAddress() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't get the email address");
      return null;
    }

    return provider.getEmailAddress();
  }

  /// {@macro act_shared_auth.MixinAuthService.setEmailAddress}
  @override
  Future<AuthPropertyResult> setEmailAddress(String address) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't set the email address");
      return const AuthPropertyResult(status: AuthPropertyStatus.genericError);
    }

    return provider.setEmailAddress(address);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmEmailAddressUpdate}
  @override
  Future<AuthPropertyResult> confirmEmailAddressUpdate({required String code}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't confirm the email address update");
      return const AuthPropertyResult(status: AuthPropertyStatus.genericError);
    }

    return provider.confirmEmailAddressUpdate(code: code);
  }

  /// {@macro act_shared_auth.MixinAuthService.deleteAccount}
  @override
  Future<AuthDeleteResult> deleteAccount() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      logsHelper.w("No provider has been set, we can't delete the account");
      return const AuthDeleteResult(status: AuthDeleteStatus.genericError);
    }

    return provider.deleteAccount();
  }

  /// {@template act_shared_auth.MixinMultiAuthService.clearProviders}
  /// Clear the providers and reset the current provider keys
  /// {@endtemplate}
  @protected
  @mustCallSuper
  Future<void> clearProviders() async {
    providers.clear();
    _currentProviderKey = null;
  }

  /// Get the current provider thanks to the [_currentProviderKey]
  ///
  /// Returns null if the provider isn't found.
  MixinAuthService? _getCurrentProvider() {
    if (_currentProviderKey == null) {
      logsHelper.w("No provider has been set as current, we can't return it");
      return null;
    }

    final provider = providers[_currentProviderKey];
    if (provider == null) {
      logsHelper.w("The wanted provider: $_currentProviderKey, isn't in the providers list");
      return null;
    }

    return provider;
  }

  /// Called when the [AuthStatus] of the [_currentProviderKey] is updated.
  ///
  /// If [providerKey] isn't equal to [_currentProviderKey], we do nothing
  void _onAuthStatusUpdated(P providerKey, AuthStatus status) {
    if (providerKey != _currentProviderKey) {
      // Do nothing
      return;
    }

    _serviceStatusCtrl.add(status);
  }

  /// {@macro act_abstract_manager.AbsWithLifeCycle.disposeLifeCycle}
  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait(_subs.map((sub) => sub.cancel()));
    await clearProviders();

    return super.disposeLifeCycle();
  }
}
