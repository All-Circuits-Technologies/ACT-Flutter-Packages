import 'dart:async';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

class OAuth2Service<P extends Enum> extends AbsWithLifeCycle
    with MixinAuthService, MixinMultiAuthService<P, AbsOAuth2ProviderService> {
  static const _logsCategory = "oauth2";

  late final FlutterAppAuth _appAuth;

  @override
  final Map<P, AbsOAuth2ProviderService> providers;

  @override
  final LogsHelper logsHelper;

  final P? _initProviderKey;

  OAuth2Service({required this.providers, P? currentProvider})
    : logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: _logsCategory),
      _initProviderKey = currentProvider;

  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    await setCurrentProviderKey(
      _initProviderKey ?? ((providers.length == 1) ? providers.keys.first : null),
    );
    _appAuth = const FlutterAppAuth();

    await Future.wait(
      providers.entries.map((entry) async {
        final provider = entry.value;
        await provider.initProvider(parentLogsHelper: logsHelper, appAuth: _appAuth);
      }),
    );
  }

  @override
  Future<void> clearProviders() async {
    final disposeList = <Future<void>>[];
    for (final entry in providers.entries) {
      disposeList.add(entry.value.disposeLifeCycle());
    }

    await Future.wait(disposeList);

    await super.clearProviders();
  }
}
