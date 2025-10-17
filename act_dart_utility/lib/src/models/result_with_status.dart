// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/mixins/mixin_result_status.dart';
import 'package:equatable/equatable.dart';

/// This class provides a way to represent the result of a request with a status
/// and the actual value of the request. Here the value can be null therefore
/// the request can be a success but the value can be null.
class ResultWithStatus<Status extends MixinResultStatus, Value> extends Equatable {
  /// This value is an enum describing the result status of a request
  /// Since it extends the [MixinResultStatus] mixin, it has a isSuccess
  /// property that returns true if the status is overall a success
  final Status status;

  /// This value is the actual result of the request
  ///
  /// Value is null if status is an error
  final Value? value;

  /// The overall status of the request is only defined by the [status] value
  bool get isSuccess => status.isSuccess;

  /// The request can be retried if the status says so
  bool get canBeRetried => status.canBeRetried;

  /// Class constructor
  const ResultWithStatus({
    required this.status,
    this.value,
  });

  /// Equatable props
  @override
  List<Object?> get props => [
        status,
        value,
      ];
}
