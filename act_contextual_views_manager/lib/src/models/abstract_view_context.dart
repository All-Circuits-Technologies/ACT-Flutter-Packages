// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

/// This represents the  context of the abstract view
/// To have an [uniqueKey] is important to be able to differentiate the views
abstract class AbstractViewContext extends Equatable {
  /// The unique key linked to this particular context
  final String uniqueKey;

  /// Class constructor
  const AbstractViewContext({
    required this.uniqueKey,
  });

  @override
  @mustCallSuper
  List<Object?> get props => [uniqueKey];
}
