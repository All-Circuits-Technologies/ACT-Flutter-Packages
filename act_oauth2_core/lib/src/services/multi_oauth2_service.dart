// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_oauth2_core/act_oauth2_core.dart';
import 'package:act_shared_auth/act_shared_auth.dart';

/// This is useful to define a multi auth service provider which supports the particularity of
/// the [AbsOAuth2ProviderService] services.
///
/// Other providers than [AbsOAuth2ProviderService] services can be set
class MultiOAuth2Service<P extends Enum> extends SimpleMultiAuthService<P> {
  /// This is the logs category linked to this class
  static const _logsCategory = "multiOauth2";

  /// This is the flutter app auth instance
  late final FlutterAppAuth _appAuth;

  /// Class constructor
  MultiOAuth2Service({required super.providers, super.currentProvider})
    : super(logsCategory: _logsCategory);

  /// {@macro act_abstract_manager.AbsWithLifeCycle.initLifeCycle}
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    _appAuth = const FlutterAppAuth();

    await Future.wait(
      providers.entries.map((entry) async {
        final provider = entry.value;
        if (provider is AbsOAuth2ProviderService) {
          await provider.initProvider(parentLogsHelper: logsHelper, appAuth: _appAuth);
        }
      }),
    );
  }

  /// {@macro act_shared_auth.MixinMultiAuthService.clearProviders}
  @override
  Future<void> clearProviders() async {
    final disposeList = <Future<void>>[];
    for (final entry in providers.entries) {
      final provider = entry.value;
      if (provider is AbsOAuth2ProviderService) {
        disposeList.add(provider.disposeLifeCycle());
      }
    }

    await Future.wait(disposeList);

    await super.clearProviders();
  }
}
