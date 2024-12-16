// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/string_utility.dart';

// Note to developers:
// Do not implement smart stuff here. Implement them as static methods within [StringUtility]
// and mirror them here.

/// This [String] extension helps checking common forms inputted values such as emails
extension ActCommonFormsStringChecks on String {
  /// Does string represents a valid email address
  ///
  /// See [StringUtility.emailAddressRegexp] for acceptance criteria
  bool get isValidEmail => StringUtility.isValidEmail(this);
}
