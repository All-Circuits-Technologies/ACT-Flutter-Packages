// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_shared_auth/act_shared_auth.dart';

/// The ways an application under test offers its users to sign in.
enum FakeProviders {
  /// The provider of the application itself.
  native,

  /// A provider the application delegates the sign in to.
  external,
}

/// An authentication service which answers what the test decided.
///
/// It records the calls it received, which is what a test reads to know which service a call
/// reached and with which arguments.
class FakeAuthService with MixinAuthService {
  /// The calls the service received, in the order it received them.
  final List<String> calls = [];

  /// The stream the service tells the application about its status through.
  final StreamController<AuthStatus> _statusCtrl = StreamController<AuthStatus>.broadcast();

  /// The status the service answers with.
  AuthStatus _authStatus;

  /// The storage the service was handed, if it was handed one.
  MixinAuthStorageService? _storageService;

  /// The tokens the service answers with.
  AuthTokens? tokens;

  /// The identifier of the user the service answers with.
  String? userId;

  /// The email address of the user the service answers with.
  String? emailAddress;

  /// Whether the service says it signed the user out.
  bool signOutAnswer;

  /// Whether the service says a user is signed in.
  bool isUserSignedAnswer;

  /// Class constructor
  FakeAuthService({
    AuthStatus authStatus = AuthStatus.signedOut,
    this.tokens,
    this.userId,
    this.emailAddress,
    this.signOutAnswer = true,
    this.isUserSignedAnswer = false,
  }) : _authStatus = authStatus;

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus => _authStatus;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _statusCtrl.stream;

  /// {@macro act_shared_auth.MixinAuthService.storageService}
  @override
  MixinAuthStorageService? get storageService => _storageService;

  /// Tells the application that the user is now [status].
  void updateStatus(AuthStatus status) {
    _authStatus = status;
    _statusCtrl.add(status);
  }

  /// Stops telling the application about the status of the user.
  Future<void> close() => _statusCtrl.close();

  /// {@macro act_shared_auth.MixinAuthService.setStorageService}
  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async {
    calls.add("setStorageService(${storageService == null ? "none" : "a storage"})");
    _storageService = storageService;
  }

  /// {@macro act_shared_auth.MixinAuthService.signUp}
  @override
  Future<AuthSignUpResult> signUp({
    required String accountId,
    required String password,
    String? email,
  }) async {
    calls.add("signUp($accountId)");

    return const AuthSignUpResult(status: AuthSignUpStatus.done);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmSignUp}
  @override
  Future<AuthSignUpResult> confirmSignUp({required String accountId, required String code}) async {
    calls.add("confirmSignUp($accountId, $code)");

    return const AuthSignUpResult(status: AuthSignUpStatus.done);
  }

  /// {@macro act_shared_auth.MixinAuthService.resendSignUpCode}
  @override
  Future<AuthSignUpResult> resendSignUpCode({required String accountId}) async {
    calls.add("resendSignUpCode($accountId)");

    return const AuthSignUpResult(status: AuthSignUpStatus.confirmSignUpWithCode);
  }

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) async {
    calls.add("signInUser($username)");

    return const AuthSignInResult(status: AuthSignInStatus.done);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmSignIn}
  @override
  Future<AuthSignInResult> confirmSignIn({required String confirmationValue}) async {
    calls.add("confirmSignIn($confirmationValue)");

    return const AuthSignInResult(status: AuthSignInStatus.done);
  }

  /// {@macro act_shared_auth.MixinAuthService.redirectToExternalUserSignIn}
  @override
  Future<AuthSignInResult> redirectToExternalUserSignIn() async {
    calls.add("redirectToExternalUserSignIn()");

    return const AuthSignInResult(status: AuthSignInStatus.done);
  }

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() async {
    calls.add("signOut()");

    return signOutAnswer;
  }

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() async {
    calls.add("isUserSigned()");

    return isUserSignedAnswer;
  }

  /// {@macro act_shared_auth.MixinAuthService.getCurrentUserId}
  @override
  Future<String?> getCurrentUserId() async {
    calls.add("getCurrentUserId()");

    return userId;
  }

  /// {@macro act_shared_auth.MixinAuthService.getTokens}
  @override
  Future<AuthTokens?> getTokens() async {
    calls.add("getTokens()");

    return tokens;
  }

  /// {@macro act_shared_auth.MixinAuthService.resetPassword}
  @override
  Future<AuthResetPwdResult> resetPassword({required String username}) async {
    calls.add("resetPassword($username)");

    return const AuthResetPwdResult(status: AuthResetPwdStatus.confirmResetPasswordWithCode);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmResetPassword}
  @override
  Future<AuthResetPwdResult> confirmResetPassword({
    required String username,
    required String newPassword,
    required String confirmationCode,
  }) async {
    calls.add("confirmResetPassword($username, $confirmationCode)");

    return const AuthResetPwdResult(status: AuthResetPwdStatus.done);
  }

  /// {@macro act_shared_auth.MixinAuthService.updatePassword}
  @override
  Future<AuthResetPwdResult> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    calls.add("updatePassword()");

    return const AuthResetPwdResult(status: AuthResetPwdStatus.done);
  }

  /// {@macro act_shared_auth.MixinAuthService.getEmailAddress}
  @override
  Future<String?> getEmailAddress() async {
    calls.add("getEmailAddress()");

    return emailAddress;
  }

  /// {@macro act_shared_auth.MixinAuthService.setEmailAddress}
  @override
  Future<AuthPropertyResult> setEmailAddress(String address) async {
    calls.add("setEmailAddress($address)");

    return const AuthPropertyResult(status: AuthPropertyStatus.confirmWithCode);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmEmailAddressUpdate}
  @override
  Future<AuthPropertyResult> confirmEmailAddressUpdate({required String code}) async {
    calls.add("confirmEmailAddressUpdate($code)");

    return const AuthPropertyResult(status: AuthPropertyStatus.done);
  }

  /// {@macro act_shared_auth.MixinAuthService.deleteAccount}
  @override
  Future<AuthDeleteResult> deleteAccount() async {
    calls.add("deleteAccount()");

    return const AuthDeleteResult(status: AuthDeleteStatus.done);
  }
}

/// An authentication service which implements no more than the mixin requires.
///
/// This is what a third party package which supports only the sign in and the sign out looks like,
/// and it is what the tests reach the default methods of the mixin through.
class BareAuthService with MixinAuthService {
  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus => AuthStatus.signedOut;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => const Stream.empty();

  /// {@macro act_shared_auth.MixinAuthService.signInUser}
  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) async =>
      const AuthSignInResult(status: AuthSignInStatus.done);

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() async => true;

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() async => false;
}

/// A storage of the authentication data which keeps them in memory.
class FakeAuthStorageService with MixinAuthStorageService {
  /// Whether the storage says it can keep the identifiers of the user.
  final bool userIdsSupported;

  /// The tokens the storage keeps.
  AuthTokens? storedTokens;

  /// The identifiers of the user the storage keeps.
  ({String username, String password})? storedUserIds;

  /// The calls the storage received, in the order it received them.
  final List<String> calls = [];

  /// Class constructor
  FakeAuthStorageService({this.userIdsSupported = true});

  /// {@macro act_shared_auth.MixinAuthStorageService.isUserIdsStorageSupported}
  @override
  Future<bool> isUserIdsStorageSupported() async => userIdsSupported;

  /// {@macro act_shared_auth.MixinAuthStorageService.storeTokens}
  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    calls.add("storeTokens()");
    storedTokens = tokens;

    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadTokens}
  @override
  Future<AuthTokens?> loadTokens() async {
    calls.add("loadTokens()");

    return storedTokens;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.clearTokens}
  @override
  Future<void> clearTokens() async {
    calls.add("clearTokens()");
    storedTokens = null;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.storeUserIds}
  @override
  Future<bool> storeUserIds({required String username, required String password}) async {
    calls.add("storeUserIds($username)");
    storedUserIds = (username: username, password: password);

    return true;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.loadUserIds}
  @override
  Future<({String username, String password})?> loadUserIds() async {
    calls.add("loadUserIds()");

    return storedUserIds;
  }

  /// {@macro act_shared_auth.MixinAuthStorageService.clearUserIds}
  @override
  Future<void> clearUserIds() async {
    calls.add("clearUserIds()");
    storedUserIds = null;
  }
}

/// A storage which implements no more than the mixin requires.
///
/// This is what a third party package which keeps the tokens but not the identifiers of the user
/// looks like.
class BareAuthStorageService with MixinAuthStorageService {
  /// {@macro act_shared_auth.MixinAuthStorageService.storeTokens}
  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async => true;

  /// {@macro act_shared_auth.MixinAuthStorageService.loadTokens}
  @override
  Future<AuthTokens?> loadTokens() async => null;

  /// {@macro act_shared_auth.MixinAuthStorageService.clearTokens}
  @override
  Future<void> clearTokens() async {}
}

/// A service over several providers whose current provider a test chooses.
///
/// Choosing a provider and reading which one is chosen are what an application does from inside
/// its own service; this one opens them to the test.
class FakeMultiAuthService extends SimpleMultiAuthService<FakeProviders> {
  /// Class constructor
  FakeMultiAuthService({required super.providers, super.currentProvider});

  /// The provider the user signs in through.
  FakeProviders? get chosenProvider => currentProviderKey;

  /// Signs the user in through [key] from now on.
  Future<void> chooseProvider(FakeProviders? key) => setCurrentProviderKey(key);

  /// Forgets the providers of the application.
  Future<void> forgetProviders() => clearProviders();
}

/// The authentication manager of an application under test.
class FakeAuthManager extends AbsAuthManager {
  /// The service the manager signs the user in through.
  final MixinAuthService service;

  /// The storage the manager keeps the authentication data in.
  final MixinAuthStorageService? storage;

  /// The statuses the manager was told about, in the order it was told.
  final List<AuthStatus> statuses = [];

  /// Class constructor
  FakeAuthManager({required this.service, this.storage});

  /// {@macro act_shared_auth.AbsAuthManager.getAuthService}
  @override
  Future<MixinAuthService> getAuthService() async => service;

  /// {@macro act_shared_auth.AbsAuthManager.getStorageService}
  @override
  Future<MixinAuthStorageService?> getStorageService() async => storage;

  /// {@macro act_shared_auth.AbsAuthManager.onAuthStatusUpdated}
  @override
  Future<void> onAuthStatusUpdated(AuthStatus status) async {
    await super.onAuthStatusUpdated(status);

    statuses.add(status);
  }
}

/// The builder of the authentication manager of an application under test.
class FakeAuthBuilder extends AbsAuthBuilder<FakeAuthManager> {
  /// Class constructor
  const FakeAuthBuilder(super.factory);
}
