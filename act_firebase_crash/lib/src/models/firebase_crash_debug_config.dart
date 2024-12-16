// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:equatable/equatable.dart';

/// This is the config linked to the firebase crash debug feature.
///
/// This describes the needed information to debug an app with firebase.
class FirebaseCrashDebugConfig extends Equatable {
  /// This is an unique identifier to identify the logs of the running application in the server
  final String identifier;

  /// This allows to give a maximum level for the logs to save in the server
  final Level level;

  /// Class constructor
  const FirebaseCrashDebugConfig({
    required this.identifier,
    this.level = Level.warning,
  });

  @override
  List<Object?> get props => [identifier, level];
}
