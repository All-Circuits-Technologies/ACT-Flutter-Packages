// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_amplify_core/act_amplify_core.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:equatable/equatable.dart';

/// Contains the configuration needed by the AmplifyManager
///
/// Because the configuration is only used once at the Amplify manager initialization, we don't
/// really interested by the comparison feature of the parent Equatable class. That's why, we add
/// the plugins list in the props knowing that the equal method may return false positive if the
/// list isn't rightfully ordered.
class AmplifyManagerConfig extends Equatable {
  /// True to enable the logger for this requester
  final bool loggerEnabled;

  /// The parent logs helper if one is needed
  final LogsHelper? parentLogsHelper;

  /// This is the config returned by the Amplify generated code
  final String amplifyConfig;

  /// Contains the list of the Amplify services to use
  final List<AbsAmplifyService> amplifyServices;

  /// Class constructor
  const AmplifyManagerConfig({
    required this.loggerEnabled,
    this.parentLogsHelper,
    required this.amplifyConfig,
    this.amplifyServices = const [],
  });

  @override
  List<Object?> get props => [
        loggerEnabled,
        parentLogsHelper,
        amplifyConfig,
        amplifyServices,
      ];
}
