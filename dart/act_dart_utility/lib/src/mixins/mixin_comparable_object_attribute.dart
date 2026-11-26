// SPDX-FileCopyrightText: 2025 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This mixin is used to represent comparable object properties, and so to compare the same
/// property of different object between themselves.
mixin MixinComparableObjectAttribute<T> on Enum {
  /// {@template act_dart_utility.MixinComparableObjectAttribute.compareTo}
  /// This method allows to compare an object thanks to the current comparable attribute
  /// {@endtemplate}
  int compareTo(T base, T toCompareWith);

  /// {@macro act_dart_utility.MixinComparableObjectAttribute.compareTo}
  ///
  /// The method inverses the result of [compareTo]. It could be used if you want to sort the
  /// element in the reverse order.
  int invertCompareTo(T base, T toCompareWith) => compareTo(toCompareWith, base);
}
