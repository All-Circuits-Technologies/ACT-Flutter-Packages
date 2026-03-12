// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/models/result_with_required_value.dart';
import 'package:act_dart_utility/src/models/status_with_extra_info.dart';
import 'package:act_dart_utility/src/types/bool_result_status.dart';

/// This class is a [ResultWithRequiredValue] with a [BoolResultStatus]
class BoolResultWithRequiredValue<Value> extends ResultWithRequiredValue<BoolResultStatus, Value> {
  /// Class constructor
  const BoolResultWithRequiredValue({required super.status, super.value, super.extraInfo});

  /// Class constructor from a [value]
  ///
  /// The [status] is set to [BoolResultStatus.success] if the [value] is not null or to
  /// [BoolResultStatus.error] if the [value] is null
  const BoolResultWithRequiredValue.fromValue({required super.value, super.extraInfo})
      : super(status: (value != null) ? BoolResultStatus.success : BoolResultStatus.error);

  /// Class constructor for an error result
  ///
  /// The [value] is set to null
  const BoolResultWithRequiredValue.error({super.extraInfo})
      : super(status: BoolResultStatus.error, value: null);

  /// Class constructor to create a [BoolResultWithRequiredValue] from a [StatusWithExtraInfo] and a
  /// value
  BoolResultWithRequiredValue.fromStatus({
    required super.statusWitExtraInfo,
    super.value,
  }) : super.fromStatus();

  /// Create a [BoolResultWithRequiredValue] from a [Future] promise
  ///
  /// The [status] is set to [BoolResultStatus.success] if the resolved value is not null or to
  /// [BoolResultStatus.error] if the resolved value is null
  static Future<BoolResultWithRequiredValue<Value>> fromFuture<Value>(
      Future<Value?> promise) async {
    final result = await promise;
    return BoolResultWithRequiredValue<Value>.fromValue(value: result);
  }
}
