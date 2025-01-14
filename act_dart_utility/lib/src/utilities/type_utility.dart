// SPDX-FileCopyrightText: 2020 - 2023 Sami Kouatli <sami.kouatli@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Utility class to help the type management
class TypeUtility {
  /// Compare if the [type] given is equals to the [value] type
  // The call of this method is to compare the value type with the type argument given; therefore
  // the value type has to be dynamic
  // ignore: avoid_annotating_with_dynamic
  static bool testValueType(Type type, dynamic value) {
    switch (type) {
      case const (bool):
        return value is bool;
      case const (double):
        return value is double;
      case const (int):
        return value is int;
      case const (String):
        return value is String;
    }

    return false;
  }
}
