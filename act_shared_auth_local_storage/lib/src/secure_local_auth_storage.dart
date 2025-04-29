import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';
import 'package:act_shared_auth_local_storage/src/mixins/mixin_auth_local_storage_conf.dart';
import 'package:act_shared_auth_local_storage/src/mixins/mixin_auth_secrets.dart';
import 'package:act_shared_auth_local_storage/src/models/auth_user_ids.dart';

class SecureLocalAuthStorage<C extends MixinAuthLocalStorageConf, S extends MixinAuthSecrets>
    with MixinAuthStorageService {
  final C _confManager;
  final S _secretsManager;

  SecureLocalAuthStorage()
    : _confManager = globalGetIt().get<C>(),
      _secretsManager = globalGetIt().get<S>();

  @override
  Future<bool> isUserIdsStorageSupported() async => _confManager.saveUserIdsInStorage.load();

  @override
  Future<AuthTokens?> loadTokens() async => _secretsManager.authTokens.load();

  @override
  Future<bool> storeTokens({required AuthTokens tokens}) async {
    await _secretsManager.authTokens.store(tokens);
    return true;
  }

  @override
  Future<({String password, String username})?> loadUserIds() async {
    final isStorageSupported = await isUserIdsStorageSupported();
    if (!isStorageSupported) {
      appLogger().w("The storage of the user ids isn't supported, can't load the information");
      return null;
    }

    final userIds = await _secretsManager.authIds.load();
    if (userIds == null) {
      // No auth ids stored in memory
      return null;
    }

    return (username: userIds.username, password: userIds.password);
  }

  @override
  Future<bool> storeUserIds({required String username, required String password}) async {
    final isStorageSupported = await isUserIdsStorageSupported();
    if (!isStorageSupported) {
      appLogger().w("The storage of the user ids isn't supported, can't store the information");
      return false;
    }

    await _secretsManager.authIds.store(AuthUserIds(username: username, password: password));
    return true;
  }
}
