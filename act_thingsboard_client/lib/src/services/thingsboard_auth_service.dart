import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

class ThingsboardAuthService extends AbsWithLifeCycle with MixinAuthService {
  final AuthStatus _authStatus;

  final StreamController<AuthStatus> _serviceStatusCtrl;

  @override
  AuthStatus get authStatus => _authStatus;

  /// {@macro act_shared_auth.MixinAuthService.authStatusStream}
  @override
  Stream<AuthStatus> get authStatusStream => _serviceStatusCtrl.stream;

  ThingsboardAuthService()
      : _authStatus = AuthStatus.signedOut,
        _serviceStatusCtrl = StreamController<AuthStatus>.broadcast();

  /// Init the service
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
  }

  @override
  Future<bool> isUserSigned() {
    // TODO: implement isUserSigned
    throw UnimplementedError();
  }

  @override
  Future<AuthSignInResult> signInUser({required String username, required String password}) {
    // TODO: implement signInUser
    throw UnimplementedError();
  }

  @override
  Future<bool> signOut() {
    // TODO: implement signOut
    throw UnimplementedError();
  }

  @override
  Future<void> disposeLifeCycle() async {
    return super.disposeLifeCycle();
  }
}
