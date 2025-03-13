// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_flutter_utility/act_flutter_utility.dart';

/// State of the request ui page
class RequestContextualActionState extends BlocStateForMixin<RequestContextualActionState> {
  /// True if the user is ok with what we request him
  final bool isOk;

  /// True if we are currently requesting the user
  final bool loading;

  /// Class constructor
  const RequestContextualActionState({
    required this.isOk,
    required this.loading,
  }) : super();

  /// Init class constructor
  const RequestContextualActionState.init({
    required this.isOk,
  })  : loading = true,
        super();

  @override
  RequestContextualActionState copyWith({
    bool? isOk,
    bool? loading,
  }) =>
      RequestContextualActionState(
        isOk: isOk ?? this.isOk,
        loading: loading ?? this.loading,
      );

  RequestContextualActionState copyWithLoadingState({
    required bool loading,
  }) =>
      copyWith(
        loading: loading,
      );

  RequestContextualActionState copyWithResultState({
    required bool isOk,
    bool? loading,
  }) =>
      copyWith(
        isOk: isOk,
        loading: loading,
      );

  @override
  List<Object?> get props => [...super.props, isOk, loading];
}
