// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/src/models/statuses/status_with_extra_info.dart';
import 'package:act_dart_result/src/types/bool_result_status.dart';

/// This class is used to return a boolean status with extra information, such as an error message
/// or a success message
class BoolStatusWithExtraInfo extends StatusWithExtraInfo<BoolResultStatus> {
  /// Class constructor
  const BoolStatusWithExtraInfo({required super.status, super.extraInfo});

  /// Constructor from a boolean value, with an optional extra information
  BoolStatusWithExtraInfo.fromBoolValue({required bool boolResult, String? extraInfo})
    : this(status: BoolResultStatus.convertBoolReturn(boolResult), extraInfo: extraInfo);

  /// Convert an asynchronous boolean result to a BoolStatusWithExtraInfo
  static Future<BoolStatusWithExtraInfo> convertAsyncBoolReturn({
    required Future<bool> boolPromise,
  }) async {
    final result = await boolPromise;
    return BoolStatusWithExtraInfo.fromBoolValue(boolResult: result);
  }
}
