// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_contextual_views_manager/src/types/view_display_status.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// This is the result returned after the view display
class ViewDisplayResult<T> extends Equatable {
  /// The view result status
  final ViewDisplayStatus status;

  /// This is the custom result, this may contain extra information which can be used by the caller
  final T? customResult;

  /// Class constructor
  const ViewDisplayResult({
    required this.status,
    this.customResult,
  });

  /// Helpful constructor to create an error result
  const ViewDisplayResult.error()
      : status = ViewDisplayStatus.error,
        customResult = null;

  /// The method returns a new [ViewDisplayResult] with the customResult casted to the generic given
  ViewDisplayResult<C> toCast<C>() => ViewDisplayResult<C>(
        status: status,
        customResult: customResult as C?,
      );

  @override
  @mustCallSuper
  List<Object?> get props => [status, customResult];
}
