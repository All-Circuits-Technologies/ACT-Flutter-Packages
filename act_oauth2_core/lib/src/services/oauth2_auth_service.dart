import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

class OAuth2AuthService<P extends Enum> extends AbsWithLifeCycle with MixinAuthService {
  static const _logsCategory = "oauth2";

  late final FlutterAppAuth _appAuth;

  final Map<P, AbsOAuth2ProviderService> _providers;

  final StreamController<AuthStatus> _serviceStatusCtrl;
  final List<StreamSubscription> _subs;

  final LogsHelper _logsHelper;

  P? _currentProviderKey;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  Stream<AuthStatus> get authStatusStream => _serviceStatusCtrl.stream;

  /// {@macro act_shared_auth.MixinAuthService.authStatus}
  @override
  AuthStatus get authStatus {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't get the right auth status");
      return AuthStatus.signedOut;
    }

    return provider.authStatus;
  }

  OAuth2AuthService({required Map<P, AbsOAuth2ProviderService> providers, P? currentProvider})
    : _providers = providers,
      _currentProviderKey =
          currentProvider ?? ((providers.length == 1) ? providers.keys.first : null),
      _serviceStatusCtrl = StreamController.broadcast(),
      _logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory),
      _subs = [];

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _appAuth = const FlutterAppAuth();

    await Future.wait(
      _providers.entries.map((entry) async {
        final provider = entry.value;
        await provider.initProvider(parentLogsHelper: _logsHelper, appAuth: _appAuth);
        _subs.add(
          provider.authStatusStream.listen((status) => _onAuthStatusUpdated(entry.key, status)),
        );
      }),
    );
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
      _logsHelper.w("No provider has been set, we can't sign up the user");
      return const AuthSignUpResult(status: AuthSignUpStatus.genericError);
    }

    return provider.signUp(accountId: accountId, password: password);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmSignUp}
  @override
  Future<AuthSignUpResult> confirmSignUp({required String accountId, required String code}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't confirm the user sign up");
      return const AuthSignUpResult(status: AuthSignUpStatus.genericError);
    }

    return provider.confirmSignUp(accountId: accountId, code: code);
  }

  /// {@macro act_shared_auth.MixinAuthService.resendSignUpCode}
  @override
  Future<AuthSignUpResult> resendSignUpCode({required String accountId}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't resend the sign up code");
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
      _currentProviderKey = providerKey;
    }

    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't sign in the user");
      return const AuthSignInResult(status: AuthSignInStatus.genericError);
    }

    return provider.signInUser(username: username, password: password);
  }

  /// {@macro act_shared_auth.MixinAuthService.signOut}
  @override
  Future<bool> signOut() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't sign out the user");
      return false;
    }

    return provider.signOut();
  }

  /// {@macro act_shared_auth.MixinAuthService.isUserSigned}
  @override
  Future<bool> isUserSigned() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't know if the user is signed or not");
      return false;
    }

    return provider.isUserSigned();
  }

  /// {@macro act_shared_auth.MixinAuthService.getCurrentUserId}
  @override
  Future<String?> getCurrentUserId() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't get the current user id");
      return null;
    }

    return provider.getCurrentUserId();
  }

  /// {@macro act_shared_auth.MixinAuthService.getAccessToken}
  @override
  Future<String?> getAccessToken() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't get the access token");
      return null;
    }

    return provider.getAccessToken();
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmSignIn}
  @override
  Future<AuthSignInResult> confirmSignIn({required String confirmationValue}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't confirm the sign in");
      return const AuthSignInResult(status: AuthSignInStatus.genericError);
    }

    return provider.confirmSignIn(confirmationValue: confirmationValue);
  }

  /// {@macro act_shared_auth.MixinAuthService.resetPassword}
  @override
  Future<AuthResetPwdResult> resetPassword({required String username}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't reset the password");
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
      _logsHelper.w("No provider has been set, we can't confirm the password reset");
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
      _logsHelper.w("No provider has been set, we can't update the password");
      return const AuthResetPwdResult(status: AuthResetPwdStatus.genericError);
    }

    return provider.updatePassword(oldPassword: oldPassword, newPassword: newPassword);
  }

  /// {@macro act_shared_auth.MixinAuthService.getEmailAddress}
  @override
  Future<String?> getEmailAddress() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't get the email address");
      return null;
    }

    return provider.getEmailAddress();
  }

  /// {@macro act_shared_auth.MixinAuthService.setEmailAddress}
  @override
  Future<AuthPropertyResult> setEmailAddress(String address) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't set the email address");
      return const AuthPropertyResult(status: AuthPropertyStatus.genericError);
    }

    return provider.setEmailAddress(address);
  }

  /// {@macro act_shared_auth.MixinAuthService.confirmEmailAddressUpdate}
  @override
  Future<AuthPropertyResult> confirmEmailAddressUpdate({required String code}) async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't confirm the email address update");
      return const AuthPropertyResult(status: AuthPropertyStatus.genericError);
    }

    return provider.confirmEmailAddressUpdate(code: code);
  }

  /// {@macro act_shared_auth.MixinAuthService.deleteAccount}
  @override
  Future<AuthDeleteResult> deleteAccount() async {
    final provider = _getCurrentProvider();
    if (provider == null) {
      _logsHelper.w("No provider has been set, we can't delete the account");
      return const AuthDeleteResult(status: AuthDeleteStatus.genericError);
    }

    return provider.deleteAccount();
  }

  AbsOAuth2ProviderService? _getCurrentProvider() {
    if (_currentProviderKey == null) {
      _logsHelper.w("No provider has been set as current, we can't return it");
      return null;
    }

    final provider = _providers[_currentProviderKey];
    if (provider == null) {
      _logsHelper.w("The wanted provider: $_currentProviderKey, isn't in the providers list");
      return null;
    }

    return provider;
  }

  Future<void> _clearProviders() async {
    final disposeList = <Future<void>>[];
    for (final entry in _providers.entries) {
      disposeList.add(entry.value.disposeLifeCycle());
    }

    await Future.wait(disposeList);

    _providers.clear();
    _currentProviderKey = null;
  }

  void _onAuthStatusUpdated(P provider, AuthStatus status) {
    if (provider != _currentProviderKey) {
      // Do nothing
      return;
    }

    _serviceStatusCtrl.add(status);
  }

  @override
  Future<void> disposeLifeCycle() async {
    await Future.wait(_subs.map((sub) => sub.cancel()));
    await _clearProviders();

    return super.disposeLifeCycle();
  }
}
