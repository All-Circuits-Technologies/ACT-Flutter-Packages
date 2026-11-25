// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:act_halo_abstract/src/models/halo_timestamped_value.dart';

/// Reads the decoded value and the timestamp held by the result of a payload getter, without going
/// through the [HaloTimestampedValue] first
extension HaloTimestampedResultExtension<T>
    on BoolResultWithRequiredValue<HaloTimestampedValue<T>> {
  /// The decoded value, null if the result is an error
  T? get data => value?.data;

  /// The timestamp attached to the decoded value, null if the result is an error or if the element
  /// didn't carry one
  DateTime? get timestamp => value?.timestamp;
}
