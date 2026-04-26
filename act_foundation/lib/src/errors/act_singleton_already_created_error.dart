// SPDX-FileCopyrightText: 2026 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This error is thrown when we tried to create a singleton that had already been created before.
///
/// [SingletonClass] is the type of the singleton class.
class ActSingletonAlreadyCreatedError<SingletonClass> extends Error {
  /// Display a representation of the error
  @override
  String toString() => "The singleton: $SingletonClass, had already been created don't do it again";
}
