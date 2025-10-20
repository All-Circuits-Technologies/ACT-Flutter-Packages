// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/mixins/mixin_result_status.dart';

/// This is a simple result status with a boolean behaviour
enum BoolResultStatus with MixinResultStatus {
  /// This is equals to a true value
  success(isSuccess: true, canBeRetried: true),

  /// This is equals to false value
  error(isSuccess: false, canBeRetried: false);

  /// {@macro act_dart_utility.MixinResultStatus.isSuccess}
  @override
  final bool isSuccess;

  /// {@macro act_dart_utility.MixinResultStatus.canBeRetried}
  @override
  final bool canBeRetried;

  /// Default constructor
  const BoolResultStatus({
    required this.isSuccess,
    required this.canBeRetried,
  });

  /// Convert a boolean result to a BoolResultStatus
  // We keep the positional parameter to easily convert the result of a method
  // ignore: avoid_positional_boolean_parameters
  static BoolResultStatus convertBoolReturn(bool boolResult) =>
      boolResult ? BoolResultStatus.success : BoolResultStatus.error;

  /// Convert an asynchronous boolean result to a BoolResultStatus
  static Future<BoolResultStatus> convertAsyncBoolReturn(Future<bool> boolPromise) async {
    final result = await boolPromise;
    return convertBoolReturn(result);
  }
}
