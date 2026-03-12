// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/mixins/mixin_result_status.dart';
import 'package:equatable/equatable.dart';

/// This class is used to represent a status with an optional extra information about the request,
/// for example an error message or a stack trace
class StatusWithExtraInfo<Status extends MixinResultStatus> extends Equatable {
  /// This value is an enum describing the result status of a request
  /// Since it extends the [MixinResultStatus] mixin, it has a isSuccess
  /// property that returns true if the status is overall a success
  final Status status;

  /// This value is an optional extra information about the request, it can be used to provide more
  /// details about the request, for example an error message or a stack trace
  final Object? extraInfo;

  /// True if the status indicates a success
  ///
  /// The overall status of the request is only defined by the [status] value
  bool get isSuccess => status.isSuccess;

  /// True if the status indicates an error
  ///
  /// The overall status of the request is only defined by the [status] value
  bool get isError => !status.isSuccess;

  /// The request can be retried if the status says so
  bool get canBeRetried => status.canBeRetried;

  /// Class constructor
  const StatusWithExtraInfo({
    required this.status,
    this.extraInfo,
  });

  /// Equatable props
  @override
  List<Object?> get props => [
        status,
        extraInfo,
      ];
}
