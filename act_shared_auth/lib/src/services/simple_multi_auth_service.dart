// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

/// This is a simple implementation of [MixinMultiAuthService]
class SimpleMultiAuthService<P extends Enum> extends AbsWithLifeCycle
    with MixinAuthService, MixinMultiAuthService<P> {
  /// This is the log category for the multi auth service
  static const logsCategory = "multiAuth";

  /// {@macro act_shared_auth.MixinMultiAuthService.providers}
  @override
  final Map<P, MixinAuthService> providers;

  /// {@macro act_shared_auth.MixinMultiAuthService.logsHelper}
  @override
  final LogsHelper logsHelper;

  /// This is the provider key to use as default in the service initialization
  final P? _initProviderKey;

  /// Class constructor
  SimpleMultiAuthService({
    required this.providers,
    P? currentProvider,
    String logsCategory = logsCategory,
  })  : logsHelper = LogsHelper(logsManager: appLogger(), logsCategory: logsCategory),
        _initProviderKey = currentProvider;

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    await setCurrentProviderKey(
        _initProviderKey ?? ((providers.length == 1) ? providers.keys.first : null));
  }
}
