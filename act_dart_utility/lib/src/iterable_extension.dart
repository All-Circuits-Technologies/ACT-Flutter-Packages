// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_dart_utility/src/iterable_utility.dart';

// Note to developers:
// Do not implement smart stuff here. Implement them as static methods within [IterableUtility]
// and mirror them here.

/// This [Iterable] extension helps finding element(s) inside Iterables
extension ActIterableLookup<T> on Iterable<T> {
  /// Return first item of current collection matching a given [predicate], null otherwise
  T? firstWhereOrNull(bool Function(T element) predicate) =>
      IterableUtility.firstWhereOrNull(this, predicate);
}
