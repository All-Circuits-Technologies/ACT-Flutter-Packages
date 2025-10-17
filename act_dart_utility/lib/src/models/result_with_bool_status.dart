// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/result_with_status.dart';
import 'package:act_dart_utility/src/types/bool_result_status.dart';

/// This class is a [ResultWithStatus] with a [BoolResultStatus]
class ResultWithBoolStatus<Value> extends ResultWithStatus<BoolResultStatus, Value> {
  /// Class constructor
  const ResultWithBoolStatus({required super.status, super.value}) : super();
}
