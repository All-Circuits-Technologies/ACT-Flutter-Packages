import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

abstract class AbsOAuth2ProviderService extends AbsWithLifeCycle with MixinAuthService {
  late final FlutterAppAuth _appAuth;

  late final LogsHelper _logsHelper;

  final String _logsCategory;

  /// This stream controller sends event when the [AuthStatus] change
  final StreamController<AuthStatus> _authStatusCtrl;

  /// The current [AuthStatus]
  AuthStatus _authStatus;

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

    if (await isUserSigned()) {
      _authStatus = AuthStatus.signedIn;
    }
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
