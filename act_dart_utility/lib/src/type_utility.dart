// Copyright (c) 2020. BMS Circuits

/// Utility class to help the type management
class TypeUtility {
  /// Compare if the [type] given is equals to the [value] type
  static bool testValueType(Type type, dynamic value) {
    switch (type) {
      case bool:
        return value is bool;
      case double:
        return value is double;
      case int:
        return value is int;
      case String:
        return value is String;
    }

    return false;
  }
}
