// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This represent the status of a view display
enum ViewDisplayStatus {
  /// This is the ok status return of the view displayed. It's a positive result.
  ok(isPositiveResult: true),

  /// This is the yes status return of the view displayed. It's a positive result.
  yes(isPositiveResult: true),

  /// This is the no status return of the view displayed.
  no(isPositiveResult: false),

  /// This is the cancel status return of the view displayed.
  cancel(isPositiveResult: false),

  /// This is the error status return of the view displayed.
  error(isPositiveResult: false),

  /// This is the custom status return of the view displayed.
  ///
  /// This status can be interpreted, but it's not seen as a positive result.
  custom(isPositiveResult: false);

  /// Class constructor
  const ViewDisplayStatus({required this.isPositiveResult});

  /// Equals to true, if we can say, it's a positive answer
  final bool isPositiveResult;
}
