// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';

/// This is the result of the load string method from assets bundle
enum AssetsBundleResult with MixinResultStatus {
  /// Everything is ok
  ok(isSuccess: true, canBeRetried: false),

  /// The asset hasn't been found
  notFound,

  /// A generic error occurred
  genericError;

  /// {@macro act_dart_result.MixinResultStatus.isSuccess}
  @override
  final bool isSuccess;

  /// {@macro act_dart_result.MixinResultStatus.canBeRetried}
  @override
  final bool canBeRetried;

  /// Enum constructor
  const AssetsBundleResult({this.isSuccess = false, this.canBeRetried = true});
}
