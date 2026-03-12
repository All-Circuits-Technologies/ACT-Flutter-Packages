// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/result_with_status.dart';
import 'package:act_dart_utility/src/models/status_with_extra_info.dart';
import 'package:act_dart_utility/src/types/bool_result_status.dart';

/// This class is a [ResultWithStatus] with a [BoolResultStatus]
class ResultWithBoolStatus<Value> extends ResultWithStatus<BoolResultStatus, Value> {
  /// Class constructor
  const ResultWithBoolStatus({required super.status, super.value, super.extraInfo}) : super();

  /// Class constructor to create a [ResultWithBoolStatus] from a [StatusWithExtraInfo] and a
  /// value
  ResultWithBoolStatus.fromStatus({
    required super.statusWitExtraInfo,
    super.value,
  }) : super.fromStatus();
}
