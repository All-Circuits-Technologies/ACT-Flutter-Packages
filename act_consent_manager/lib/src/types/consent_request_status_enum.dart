// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';

/// This enum represents the status of a consent load request
enum ConsentLoadStatus with MixinResultStatus {
  /// The load operation was successful
  success,

  /// The load operation failed but can be retried later
  retryLater,

  /// The load operation failed and should not be retried
  failed;

  /// Returns true if the status is [success]
  @override
  bool get isSuccess => this == ConsentLoadStatus.success;

  /// Returns true if the status is not [failed]
  @override
  bool get canBeRetried => this != ConsentLoadStatus.failed;
}
