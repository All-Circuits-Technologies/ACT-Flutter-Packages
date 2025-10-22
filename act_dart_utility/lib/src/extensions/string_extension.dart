// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/utilities/string_utility.dart';

// Note to developers:
// Do not implement smart stuff here. Implement them as static methods within [StringUtility]
// and mirror them here.

/// This [String] extension adds [StringUtility] methods to the [String] class.
extension ActCommonFormsStringChecks on String {
  /// Does string represents a valid email address
  ///
  /// See [StringUtility.emailAddressRegexp] for acceptance criteria
  bool get isValidEmail => StringUtility.isValidEmail(this);

  /// {@macro act_dart_utility.StringUtility.splitWithoutEmpty}
  List<String> splitWithoutEmpty(Pattern pattern) => StringUtility.splitWithoutEmpty(this, pattern);

  /// {@macro act_dart_utility.StringUtility.fromAsciiToHex}
  String fromAsciiToHex() => StringUtility.fromAsciiToHex(this);

  /// {@macro act_dart_utility.StringUtility.fromUtf16ToHex}
  String fromUtf16ToHex() => StringUtility.fromUtf16ToHex(this);
}
