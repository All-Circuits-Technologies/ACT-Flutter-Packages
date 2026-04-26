// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_life_cycle/act_life_cycle.dart';
import 'package:act_logger_manager/act_logger_manager.dart';

/// Abstract class for AWS IoT services.
abstract class AbsAwsIotService extends AbsWithLifeCycle {
  /// Logs helper used by the service.
  final LogsHelper logsHelper;

  /// Class constructor.
  AbsAwsIotService({
    required LogsHelper iotManagerLogsHelper,
    required String logsCategory,
  }) : logsHelper = iotManagerLogsHelper.createSubLogger(subCategory: logsCategory);
}
