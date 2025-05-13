import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

class SimpleMultiAuthService<P extends Enum> extends AbsWithLifeCycle
    with MixinAuthService, MixinMultiAuthService<P, MixinAuthService> {
  static const _logsCategory = "multiAuth";

  @override
  final Map<P, MixinAuthService> providers;

  @override
  final LogsHelper logsHelper;

  final P? _initProviderKey;

  SimpleMultiAuthService({required this.providers, P? currentProvider})
      : logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory),
        _initProviderKey = currentProvider;

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    await setCurrentProviderKey(
        _initProviderKey ?? ((providers.length == 1) ? providers.keys.first : null));
  }
}
