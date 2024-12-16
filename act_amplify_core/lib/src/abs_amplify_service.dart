// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';

/// This is the abstract skeleton for the amplify services
abstract class AbsAmplifyService {
  /// Asynchronous initialization of the service
  @mustCallSuper
  Future<void> initService({
    required LogsHelper parentLogsHelper,
  });

  /// Get the list of the linked Amplify plugin needed by the service
  Future<List<AmplifyPluginInterface>> getLinkedPluginsList();

  /// Method called asynchronously after the view is initialised
  ///
  /// This [BuildContext] is above the Navigator (therefore it can't be used to access it)
  @mustCallSuper
  Future<void> initAfterView(BuildContext context) async {}

  /// Default dispose for service
  @mustCallSuper
  Future<void> dispose() async {}
}
