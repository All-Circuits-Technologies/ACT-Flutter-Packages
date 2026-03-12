// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/mixins/mixin_result_status.dart';
import 'package:act_dart_utility/src/models/status_with_extra_info.dart';

/// This class provides a way to represent the result of a request with a status
/// and the actual value of the request. Here the value can be null therefore
/// the request can be a success but the value can be null.
class ResultWithStatus<Status extends MixinResultStatus, Value>
    extends StatusWithExtraInfo<Status> {
  /// This value is the actual result of the request
  ///
  /// Value is null if status is an error
  final Value? value;

  /// Class constructor
  const ResultWithStatus({
    required super.status,
    super.extraInfo,
    this.value,
  });

  /// Class constructor to create a [ResultWithStatus] from a [StatusWithExtraInfo] and a
  /// value
  ResultWithStatus.fromStatus({
    required StatusWithExtraInfo<Status> statusWitExtraInfo,
    this.value,
  }) : super(status: statusWitExtraInfo.status, extraInfo: statusWitExtraInfo.extraInfo);

  /// Equatable props
  @override
  List<Object?> get props => [
        ...super.props,
        value,
      ];
}
