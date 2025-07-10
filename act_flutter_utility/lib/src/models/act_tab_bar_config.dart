// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// This is the config for using the ACT tab bars, each element describe the tab bar and the linked
/// tab bar view
class ActTabBarConfig extends Equatable {
  /// The tab bar title
  final String title;

  /// The tab bar child
  final Widget child;

  /// Class constructor
  const ActTabBarConfig({
    required this.title,
    required this.child,
  });

  /// Class properties
  @override
  List<Object?> get props => [
        title,
        child,
      ];
}
