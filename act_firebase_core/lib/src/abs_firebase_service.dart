// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_abstract_manager/act_abstract_manager.dart';
import 'package:act_global_manager/act_global_manager.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/widgets.dart';

/// This is the abstract skeleton for the firebase services
abstract class AbsFirebaseService extends AbsWithLifeCycle {
  /// Asynchronous initialization of the service
  @mustCallSuper
  @override
  Future<void> initLifeCycle({
    LogsHelper? parentLogsHelper,
  });

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
