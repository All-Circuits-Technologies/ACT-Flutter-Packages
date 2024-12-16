// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_amplify_core/src/abs_amplify_service.dart';
import 'package:act_amplify_core/src/models/amplify_manager_config.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/widgets.dart';

/// This is the abstract builder for the AbsAmplifyManager manager
abstract class AbsAmplifyBuilder<T extends AbsAmplifyManager> extends ManagerBuilder<T> {
  /// Class constructor
  AbsAmplifyBuilder(super.factory);

  @override
  Iterable<Type> dependsOn() => [LoggerManager];
}

abstract class AbsAmplifyManager extends AbstractManager {
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
  Future<void> initManager() async {
    final config = await getAmplifyConfig();
    _logsHelper = LogsHelper(
      logsManager: globalGetIt().get<LoggerManager>(),
      logsCategory: _amplifyLogsCategory,
      enableLog: config.loggerEnabled,
    );
    _services = config.amplifyServices;

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

      await Amplify.configure(config.amplifyConfig);
    } catch (error) {
      _logsHelper.e("An error occurred while configuring Amplify: $error");
      return;
    }

    for (final service in _services) {
      await service.initService(parentLogsHelper: _logsHelper);
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

  /// Default dispose for manager
  @override
  Future<void> dispose() async {
    await super.dispose();

    for (final service in _services) {
      await service.dispose();
    }
  }
}
