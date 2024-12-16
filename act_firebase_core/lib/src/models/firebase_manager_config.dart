// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_firebase_core/src/abs_firebase_service.dart';
import 'package:act_logger_manager/act_logger_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';

/// Contains the configuration needed by the AmplifyManager
class FirebaseManagerConfig extends Equatable {
  /// True to enable the logger for this requester
  final bool loggerEnabled;

  /// The parent logs helper if one is needed
  final LogsHelper? parentLogsHelper;

  /// Firebase app name
  final String? firebaseAppName;

  /// Firebase options
  final FirebaseOptions? options;

  /// Firebase services
  final List<AbsFirebaseService> firebaseServices;

  /// Class constructor
  const FirebaseManagerConfig({
    required this.loggerEnabled,
    this.parentLogsHelper,
    this.firebaseAppName,
    this.options,
    this.firebaseServices = const [],
  });

  @override
  List<Object?> get props => [
        loggerEnabled,
        parentLogsHelper,
        firebaseAppName,
        options,
        firebaseServices,
      ];
}
