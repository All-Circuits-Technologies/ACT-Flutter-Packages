// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:convert';

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_amplify_core/src/abs_amplify_service.dart';
import 'package:act_amplify_core/src/models/amplify_manager_config.dart';
import 'package:act_config_manager/act_config_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/widgets.dart';

/// This is the abstract builder for the AbsAmplifyManager manager
abstract class AbsAmplifyBuilder<T extends AbsAmplifyManager, C extends AbstractConfigManager>
    extends AbsManagerBuilder<T> {
  /// Class constructor
  AbsAmplifyBuilder(super.factory);

  @override
  Iterable<Type> dependsOn() => [LoggerManager, C];
}

/// This is the abstract manager for Amplify features
abstract class AbsAmplifyManager extends AbsWithLifeCycle {
  /// This is the category for the amplify logs helper
  static const _amplifyLogsCategory = "amplify";

  /// The manager for logs helper
  late final LogsHelper _logsHelper;

  /// This contains the amplify services managed by the amplify manager
  late final List<AbsAmplifyService> _services;

  /// Get the configuration linked to Amplify
  /// This has to be overridden by the derived class
  @protected
  Future<AmplifyManagerConfig> getAmplifyConfig();

  /// Init manager method
  @override
  Future<void> initLifeCycle() async {
    await super.initLifeCycle();
    final config = await getAmplifyConfig();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _amplifyLogsCategory,
      enableLog: config.loggerEnabled,
    );
    _services = config.amplifyServices;

    // Update the config by the services if needed
    final updatedAmplifyConfig = await _manageAmplifyConfigUpdate(config);

    if (updatedAmplifyConfig == null) {
      return;
    }

    try {
      // Add plugins needed by the services.
      //
      // If two services need the same plugin that could create errors, but that what we want.
      // Because two plugins could be configured differently between the services, in that case we
      // want Amplify to fail to give us the information.
      for (final service in _services) {
        final pluginsList = await service.getLinkedPluginsList();
        await Amplify.addPlugins(pluginsList);
      }

      await Amplify.configure(updatedAmplifyConfig);
    } catch (error) {
      _logsHelper.e("An error occurred while configuring Amplify: $error");
      return;
    }

    for (final service in _services) {
      await service.initLifeCycle(parentLogsHelper: _logsHelper);
    }
  }

  /// Called to initialize some service after the first view is built
  @override
  Future<void> initAfterView(BuildContext context) async {
    await super.initAfterView(context);

    for (final service in _services) {
      // In that case, the build context can be accessed through async method
      // ignore: use_build_context_synchronously
      await service.initAfterView(context);
    }
  }

  /// Iterate on the amplify services to update, if needed, the amplify configuration object
  Future<String?> _manageAmplifyConfigUpdate(AmplifyManagerConfig managerConfig) async {
    if (managerConfig.amplifyServices.isEmpty) {
      // If there are no services, we don't need to go further
      return managerConfig.amplifyConfig;
    }

    AmplifyConfig config;

    try {
      final jsonConfig = jsonDecode(managerConfig.amplifyConfig) as Map<String, dynamic>;
      config = AmplifyConfig.fromJson(jsonConfig);
    } catch (error) {
      _logsHelper.e("An error occurred when tried to decode the JSON amplify configuration");
      return null;
    }

    for (final service in managerConfig.amplifyServices) {
      final tmpConfig = await service.updateAmplifyConfig(config);
      if (tmpConfig == null) {
        _logsHelper.e("An error occurred when tried to update the amplify config in a service");
        return null;
      }

      config = tmpConfig;
    }

    return jsonEncode(config.toJson());
  }

  /// Default dispose for manager
  @override
  Future<void> disposeLifeCycle() async {
    for (final service in _services) {
      await service.disposeLifeCycle();
    }

    await super.disposeLifeCycle();
  }
}
