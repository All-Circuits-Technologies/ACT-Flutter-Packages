// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/bool_helper.dart';

/// This class provides a set of [String] helpers, not provided by Dart.
///
/// String parsing methods
/// ----------------------
///
/// Others basic types feature both
/// - a formatMacAddress function which formats a String value Mac Address to a String with O added if number is under 10
///
/// This helper provides this missing function.
///
/// Extending [String] type
/// ---------------------
///
abstract class StringUtility {
  /// Parse [source] as a [String].
  ///
  /// The [source] is expected to be a String and must not be null.

  static const separator = ":";

  /// Format String to Mac Address
  /// When the Mac Address contains hexadecimal values without lead zero and not capitalized
  static String formatMacAddress({required String macAddress}) {
    final macAddressFromDevice = macAddress.split(separator);
    final macAddressFormatedList = <String>[];
    for (final element in macAddressFromDevice) {
      macAddressFormatedList.add(element.padLeft(2, '0'));
    }
    return macAddressFormatedList.join(separator).toUpperCase();
  }

  /// Format String with first letter capital
  static String firstLetterCapital({required String string}) {
    return (string.length > 1)
        ? string[0].toUpperCase() + string.substring(1)
        : string.toUpperCase();
  }

  /// Useful method to parse a string value to the wanted type
  ///
  /// The method returns null if the parsing has failed or if the value given is null
  static T? parseStrValue<T>(String? value) {
    if (value == null) {
      return null;
    }

    dynamic castedValue;

    switch (T) {
      case double:
        castedValue = double.tryParse(value);
        break;
      case int:
        castedValue = int.tryParse(value);
        break;
      case String:
        castedValue = value;
        break;
      case bool:
        castedValue = BoolHelper.tryParse(value);
      default:
        throw Exception("The given type: $T isn't managed by the method");
    }

    return castedValue as T?;
  }
}
