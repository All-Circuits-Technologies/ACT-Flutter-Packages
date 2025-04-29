import 'package:act_shared_auth/act_shared_auth.dart';

mixin MixinAuthStorageService {
  Future<bool> isUserIdsStorageSupported() async => false;

  Future<bool> storeTokens({
    required AuthTokens tokens,
  }) async =>
      _crashUnimplemented("storeTokens");

  Future<AuthTokens?> loadTokens() async => _crashUnimplemented("loadTokens");

  Future<bool> storeUserIds({
    required String username,
    required String password,
  }) async =>
      _crashUnimplemented("storeUserIds");

  Future<({String username, String password})?> loadUserIds() async =>
      _crashUnimplemented("loadUserIds");

  /// This trap forcibly crashes the app when unsupported methods are reached
  ///
  /// Service either misses this method implementation or it does not support it at all.
  /// If a service can support missing method but do not implement it yet, developer may want to
  /// implement it and return notSupportedYet error.
  Never _crashUnimplemented(String method) {
    final err = "$runtimeType service does not implement $method";
    assert(false, err);
    throw Exception(err);
  }
}
