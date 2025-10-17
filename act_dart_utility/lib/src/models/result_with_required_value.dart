// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/mixins/mixin_result_status.dart';
import 'package:act_dart_utility/src/models/result_with_status.dart';

/// This class is similar to [ResultWithStatus] but the value is
/// not supposed to be null. Therefore the request is a success only if the
/// status is a success and the value is not null.
class ResultWithRequiredValue<Status extends MixinResultStatus, Value>
    extends ResultWithStatus<Status, Value> {
  /// Since the value is not nullable, the request is a success only if the
  /// status is a success and the [value] is not null
  @override
  bool get isSuccess => super.isSuccess && value != null;

  /// Class constructor
  const ResultWithRequiredValue({required super.status, super.value});
}
