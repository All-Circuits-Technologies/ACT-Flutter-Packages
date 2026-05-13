// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_result/act_dart_result.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// {@macro act_dart_result.AsyncCallStatus}
///
/// This uses the [ResultWithStatus] class to represent the result of the asynchronous call
typedef AsyncCallResult<Status extends MixinResultStatus, Value> =
    AsyncCallStatus<ResultWithStatus<Status, Value>>;

/// {@macro act_dart_result.AsyncCallStatus}
///
/// This uses the [ResultWithRequiredValue] class to represent the result of the asynchronous call
typedef AsyncCallResultRequiredValue<Status extends MixinResultStatus, Value> =
    AsyncCallStatus<ResultWithRequiredValue<Status, Value>>;

/// {@macro act_dart_result.AsyncCallStatus}
///
/// This uses the [BoolResultStatus] class to represent the result of the asynchronous call
typedef AsyncCallBoolStatus = AsyncCallStatus<BoolResultStatus>;

/// {@template act_dart_result.AsyncCallStatus}
/// This class is used to represent the status of an asynchronous call, it contains the result of
/// the call, the loading state and the status of the call.
/// {@endtemplate}
class AsyncCallStatus<Result extends MixinResultStatus> extends Equatable with MixinResultStatus {
  /// This is the result of the request, it can be null if the request is still loading.
  final Result? result;

  /// This value is true if the request is still loading, false otherwise
  final bool loading;

  /// {@template act_dart_result.AsyncCallStatus.isSuccess}
  /// True if the status indicates a success.
  ///
  /// Returns false if result is null.
  /// {@endtemplate}
  @override
  bool get isSuccess => result?.isSuccess ?? false;

  /// {@template act_dart_result.AsyncCallStatus.isError}
  /// True if the status indicates an error.
  ///
  /// Returns false if result is null.
  /// {@endtemplate}
  @override
  bool get isError => result?.isError ?? false;

  /// {@template act_dart_result.AsyncCallStatus.canBeRetried}
  /// The request can be retried if the status says so.
  ///
  /// Returns false if result is null.
  /// {@endtemplate}
  @override
  bool get canBeRetried => result?.canBeRetried ?? false;

  /// Class constructor
  const AsyncCallStatus({required this.loading, required this.result});

  /// {@template act_dart_result.AsyncCallStatus.init}
  /// This constructor is used to create an initial state of the asynchronous call, where the
  /// request is not loading and the result is null.
  /// {@endtemplate}
  const AsyncCallStatus.init() : loading = false, result = null;

  /// {@template act_dart_result.AsyncCallStatus.initLoading}
  /// This constructor is used to create an initial loading state of the asynchronous call, where
  /// the request is loading and the result is null.
  /// {@endtemplate}
  const AsyncCallStatus.initLoading() : loading = true, result = null;

  /// {@template act_dart_result.AsyncCallStatus.copyWith}
  /// This method is used to copy the current instance of [AsyncCallStatus] with new values for
  /// the properties.
  ///
  /// The [forceResultValue] parameter is used to force the result value to be updated even if the
  /// [result] parameter is null.
  /// {@endtemplate}
  AsyncCallStatus<Result> copyWith({
    bool? loading,
    Result? result,
    bool forceResultValue = false,
  }) => AsyncCallStatus(
    loading: loading ?? this.loading,
    result: result ?? (forceResultValue ? null : this.result),
  );

  /// This method is used to copy the current instance of [AsyncCallStatus] with a new loading
  /// value.
  ///
  /// It resets the result value to null.
  AsyncCallStatus<Result> copyWithLoading() => copyWith(loading: true, forceResultValue: true);

  /// This method is used to copy the current instance of [AsyncCallStatus] with a new result
  /// value.
  AsyncCallStatus<Result> copyWithResult({required Result result}) =>
      copyWith(result: result, loading: false);

  /// This method is used to copy and reset the current instance of [AsyncCallStatus] to an initial
  /// state
  AsyncCallStatus<Result> copyWithReset({bool loading = false}) =>
      copyWith(loading: loading, forceResultValue: true);

  /// Equatable props
  @mustCallSuper
  @override
  List<Object?> get props => [loading, result];
}
