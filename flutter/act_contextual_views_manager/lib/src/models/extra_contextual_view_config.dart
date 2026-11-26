// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'dart:async';

import 'package:act_contextual_views_manager/act_contextual_views_manager.dart';
import 'package:equatable/equatable.dart';

/// This callback is called to request the user and knows if it's ok or not
typedef RequestContextualActionCallback = FutureOr<bool> Function();

/// This callback is called when the view has ended its purpose and we want to go further
typedef CallWhenEnded = Future<void> Function(ViewDisplayStatus status);

/// This is the extra object passed to the page created by a RouterManager
class ExtraContextualViewConfig<T extends AbstractViewContext> extends Equatable {
  /// This is the abstract view context linked to the displaying of the page
  final T context;

  /// This is the method to call when the page has reached its purpose
  final CallWhenEnded callWhenEnded;

  /// When not null, this method has to be called to request the user to do something
  final RequestContextualActionCallback? requestExtraAction;

  /// Class constructor
  const ExtraContextualViewConfig({
    required this.context,
    required this.callWhenEnded,
    this.requestExtraAction,
  });

  @override
  List<Object?> get props => [context, callWhenEnded, requestExtraAction];
}
