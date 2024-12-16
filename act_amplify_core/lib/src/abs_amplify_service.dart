// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

/// This is the abstract skeleton for the amplify services
abstract class AbsAmplifyService extends AbstractService {
  /// Asynchronous initialization of the service after the Amplify.configure call
  @mustCallSuper
  @override
  Future<void> initService({
    LogsHelper? parentLogsHelper,
  });

  /// The service may need to extend the amplify configuration
  ///
  /// This method allows to update the amplify config
  Future<AmplifyConfig?> updateAmplifyConfig(AmplifyConfig config) async => config;

  /// Get the list of the linked Amplify plugin needed by the service
  Future<List<AmplifyPluginInterface>> getLinkedPluginsList();

  /// Create a logs helper from a parent logs helper if one is given or from start if
  /// [parentLogsHelper] is null.
  @protected
  static LogsHelper createLogsHelper({
    required String logCategory,
    LogsHelper? parentLogsHelper,
  }) =>
      parentLogsHelper?.createASubLogsHelper(logCategory) ??
      LogsHelper(
        logsManager: globalGetIt().get<LoggerManager>(),
        logsCategory: logCategory,
      );
}
