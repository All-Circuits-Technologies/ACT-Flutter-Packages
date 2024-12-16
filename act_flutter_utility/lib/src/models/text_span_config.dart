// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';

/// Contains useful information to configure a [TextSpan]. This class is used with the some methods
/// of the class [TextUtility]
class TextSpanConfig extends Equatable {
  /// This is the [TextStyle] to use with the [TextSpan], if null, the default one is used
  final TextStyle? style;

  /// This is the [GestureRecognizer] to use with the [TextSpan], if null, the default one is used
  final GestureRecognizer? recognizer;

  /// Class constructor
  const TextSpanConfig({
    this.style,
    this.recognizer,
  });

  /// Properties of the class
  @override
  List<Object?> get props => [style, recognizer];
}
