import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/cupertino.dart';

abstract class AbsOAuth2ProviderService extends AbsWithLifeCycle with MixinAuthService {
  static const redirectUrlSeparator = ":/";
  static const redirectUrlSuffix = "${redirectUrlSeparator}oauthredirect";

  late final FlutterAppAuth _appAuth;

  late final DefaultOAuth2Conf _conf;

  late final LogsHelper _logsHelper;

  final String _logsCategory;

  /// This stream controller sends event when the [AuthStatus] change
  final StreamController<AuthStatus> _authStatusCtrl;

  /// The current [AuthStatus]
  AuthStatus _authStatus;

  AuthTokens _authTokens;

  MixinAuthStorageService? _storageService;

  @protected
  FlutterAppAuth get appAuth => _appAuth;

  @protected
  LogsHelper get logsHelper => _logsHelper;

  @override
  AuthStatus get authStatus => _authStatus;

  @override
  Stream<AuthStatus> get authStatusStream => _authStatusCtrl.stream;

  AbsOAuth2ProviderService({required String logsCategory})
    : _authStatus = AuthStatus.signedOut,
      _authTokens = const AuthTokens(),
      _authStatusCtrl = StreamController.broadcast(),
      _logsCategory = logsCategory;

  Future<void> initProvider({
    required LogsHelper parentLogsHelper,
    required FlutterAppAuth appAuth,
  }) async {
    _logsHelper = parentLogsHelper.createASubLogsHelper(_logsCategory);
    _appAuth = appAuth;

    return initLifeCycle();
  }

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();

    _conf = await getDefaultOAuth2Conf();

    if (await isUserSigned()) {
      _authStatus = AuthStatus.signedIn;
    }
  }

  @override
  Future<void> setStorageService(MixinAuthStorageService? storageService) async {
    if (storageService == _storageService) {
      // Nothing to do
      return;
    }

    _storageService = storageService;

    if (storageService == null) {
      // Nothing more to do
      return;
    }

    await _loadAndSetTokensFromMemoryIfRelevant(storageService);
  }

  Future<void> _loadAndSetTokensFromMemoryIfRelevant(MixinAuthStorageService storageService) async {
    final tokensFromMemory = await storageService.loadTokens();
    if (tokensFromMemory == null ||
        (tokensFromMemory.accessToken == null && tokensFromMemory.refreshToken == null)) {
      // Nothing to set
      return;
    }

    if (_authTokens.accessToken != null || _authTokens.refreshToken != null) {
      // We already have information in the app memory, we don't want to erase them with those which
      // are stored in cold memory.
      // But we also want to store the current one; therefore, we erase the cold memory with the
      // current.
      await storageService.storeTokens(tokens: _authTokens);
      return;
    }

    _authTokens = tokensFromMemory;
  }

  @protected
  Future<DefaultOAuth2Conf> getDefaultOAuth2Conf();

  @override
  Future<bool> isUserSigned() async {
    final isUserSigned =
        (_authTokens.accessToken?.isValid ?? false) || (_authTokens.refreshToken?.isValid ?? false);
    if (!isUserSigned) {
      // If the token and the refresh token are expired, we consider that we are signed out
      setAuthStatus(AuthStatus.signedOut);
    }

    return isUserSigned;
  }

  /// To call in order to the set the [AuthStatus] and send an event to the [AuthStatus] stream
  @protected
  void setAuthStatus(AuthStatus value) {
    if (value == _authStatus) {
      // Nothing to do
      return;
    }

    _logsHelper.d("New auth value: $value");
    _authStatus = value;
    _authStatusCtrl.add(value);
  }

  @override
  Future<void> disposeLifeCycle() async {
    await _authStatusCtrl.close();
    return super.disposeLifeCycle();
  }
}
