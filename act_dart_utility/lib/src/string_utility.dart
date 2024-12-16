// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Nicolas Butet <nicolas.butet@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/bool_helper.dart';

/// This class provides a set of [String] helpers, not provided by Dart.
///
/// It especially contains:
/// - various static constants you might need, such as email validation regexp
/// - parsing methods
/// - sanitization methods such as MAC address sanitization and word capitalization
/// - test methods such as email validity verification
abstract class StringUtility {
  /// MAC address bytes separator
  static const macAddressSeparator = ":";

  /// Email address validation regexp
  ///
  /// Voluntary accepts a larger scope for simplicity reasons since an accurate regexp would be very
  /// complex. If we want to be accurate one day, we may want to use a dedicated package instead.
  ///
  /// Currently checks that string has one and only one @ sign, without any spaces.
  /// Note that untrimmed email addresses are rejected.
  ///
  /// See also [isValidEmail].
  static final emailAddressRegexp = RegExp(r'^[^@ ]+@[^@ ]+$');

  /// Sanitize a MAC address
  ///
  /// Returns a properly formated MAC address (such as "00:01:20:0A:BB:CC")
  /// given a maybe poorly formated MAC address (such as "0:1:20:a:bb:CC")
  static String formatMacAddress({required String macAddress}) =>
      macAddress.split(macAddressSeparator).map((e) => e.padLeft(2, '0')).join(macAddressSeparator);

  /// Format String with first letter capital
  static String firstLetterCapital({required String string}) =>
      string.isNotEmpty ? string[0].toUpperCase() + string.substring(1) : "";

  /// Check if given string represents a valid email address
  ///
  /// See [emailAddressRegexp] for acceptance criteria
  static bool isValidEmail(String string) => emailAddressRegexp.hasMatch(string);

  /// Useful method to parse a string value to the wanted type
  ///
  /// The method returns null if the parsing has failed or if the value given is null
  static T? parseStrValue<T>(String? value) {
    if (value == null) {
      return null;
    }

    dynamic castedValue;

    switch (T) {
      case const (double):
        castedValue = double.tryParse(value);
        break;
      case const (int):
        castedValue = int.tryParse(value);
        break;
      case const (String):
        castedValue = value;
        break;
      case const (bool):
        castedValue = BoolHelper.tryParse(value);
      default:
        throw Exception("The given type: $T isn't managed by the method");
    }

    return castedValue as T?;
  }
}
