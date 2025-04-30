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

  SimpleMultiAuthService({required Map<P, MixinAuthService> providers, P? currentProvider})
      : providers = providers,
        logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory) {
    currentProviderKey = currentProvider ?? ((providers.length == 1) ? providers.keys.first : null);
  }
}
