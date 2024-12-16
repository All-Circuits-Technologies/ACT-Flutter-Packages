// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:flutter/widgets.dart';

/// This is the abstract skeleton for the firebase services
abstract class AbsFirebaseService {
  /// Asynchronous initialization of the service
  @mustCallSuper
  Future<void> initService({
    required LogsHelper parentLogsHelper,
  });

  /// Method called asynchronously after the view is initialised
  ///
  /// This [BuildContext] is above the Navigator (therefore it can't be used to access it)
  @mustCallSuper
  Future<void> initAfterView(BuildContext context) async {}

  /// Default dispose for service
  @mustCallSuper
  Future<void> dispose() async {}
}
