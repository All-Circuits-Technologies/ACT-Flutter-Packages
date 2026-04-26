// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This error is thrown when we tried to get the instance of a not created singleton.
///
/// [SingletonClass] is the type of the singleton class.
class ActSingletonNotCreatedError<SingletonClass> extends Error {
  /// Display a representation of the error
  @override
  String toString() =>
      "The singleton: $SingletonClass, hadn't been created before we tried to access singleton "
      "instance";
}
