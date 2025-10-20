// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/utilities/string_list_utility.dart';

// Note to developers:
// Do not implement smart stuff here. Implement them as static methods within [StringUtility]
// and mirror them here.

/// This List\<String\> extension adds [StringListUtility] methods to the List\<String\> class.
extension ActStringListExtension on List<String> {
  /// {@macro act_dart_utility.StringListUtility.trim}
  List<String> trim({bool growable = true}) => StringListUtility.trim(this, growable: growable);
}
