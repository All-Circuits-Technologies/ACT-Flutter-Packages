// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/act_dart_utility.dart';
import 'package:equatable/equatable.dart';

/// This class provides a way to represent the result of a request with a status
/// and the actual value of the request. Here the value can be null therefore
/// the request can be a success but the value can be null.
class StatusWithNullableValueResult<Status extends MixinResultStatus, Value>
    extends Equatable {
  /// This value is an enum describing the result status of a request
  /// Since it extends the [MixinResultStatus] mixin, it has a isSuccess
  /// property that returns true if the status is overall a success
  final Status status;

  /// This value is the actual result of the request
  final Value? value; // Value is null if status is an error

  /// The overall status of the request is only defined by the [status] value
  bool get isSuccess => status.isSuccess;

  /// The request can be retried if the status says so
  bool get canBeRetried => status.canBeRetried;

  /// Constructor
  const StatusWithNullableValueResult({
    required this.status,
    this.value,
  });

  @override
  List<Object?> get props => [
        status,
        value,
      ];
}

/// This class is similar to [StatusWithNullableValueResult] but the value is
/// not supposed to be null. Therefore the request is a success only if the
/// status is a success and the value is not null.
class StatusWithNotNullValueResult<Status extends MixinResultStatus, Value>
    extends StatusWithNullableValueResult<Status, Value> {
  /// Since the value is not nullable, the request is a success only if the
  /// status is a success and the [value] is not null
  @override
  bool get isSuccess => super.isSuccess && value != null;

  /// Constructor
  const StatusWithNotNullValueResult({
    required super.status,
    super.value,
  });
}
