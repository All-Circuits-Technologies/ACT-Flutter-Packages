// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// State of the request ui page
abstract class RequestUserUiState extends Equatable {
  /// True if the user is ok with what we request him
  final bool isOk;

  /// True if we are currently requesting the user
  final bool loading;

  /// Class constructor
  RequestUserUiState({
    required RequestUserUiState previousState,
    bool? isOk,
    bool? loading,
  })  : isOk = isOk ?? previousState.isOk,
        loading = loading ?? previousState.loading,
        super();

  /// Init class constructor
  const RequestUserUiState.init({
    required this.isOk,
  })  : loading = true,
        super();

  @override
  List<Object?> get props => [isOk, loading];
}

/// Init state
class RequestUserUiInitState extends RequestUserUiState {
  /// Class constructor
  const RequestUserUiInitState({
    required super.isOk,
  }) : super.init();
}

/// Called when the request result has been received
class RequestUserUiUpdateState extends RequestUserUiState {
  /// Class constructor
  RequestUserUiUpdateState({
    required super.previousState,
    required bool super.isOk,
    super.loading,
  }) : super();
}

/// Called when the request is processing
class RequestUserUiLoadingState extends RequestUserUiState {
  RequestUserUiLoadingState({
    required super.previousState,
    required bool super.loading,
  }) : super();
}
