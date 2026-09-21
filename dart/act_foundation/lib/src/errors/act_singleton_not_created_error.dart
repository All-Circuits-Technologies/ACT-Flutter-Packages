// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_foundation/src/errors/act_error.dart';

/// This error is thrown when we tried to get the instance of a not created singleton.
///
/// [SingletonClass] is the type of the singleton class.
class ActSingletonNotCreatedError<SingletonClass> extends ActError {
  /// Class constructor
  ActSingletonNotCreatedError()
    : super(
        "The singleton: $SingletonClass, hadn't been created before we tried to access "
        "singleton instance",
      );
}
