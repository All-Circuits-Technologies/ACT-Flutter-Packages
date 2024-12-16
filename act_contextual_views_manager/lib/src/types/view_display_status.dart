// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This represent the status of a view display
enum ViewDisplayStatus {
  ok(isPositiveResult: true),
  yes(isPositiveResult: true),
  no(isPositiveResult: false),
  cancel(isPositiveResult: false),
  error(isPositiveResult: false),
  custom(isPositiveResult: false);

  /// Class constructor
  const ViewDisplayStatus({required this.isPositiveResult});

  /// Equals to true, if we can say, it's a positive answer
  final bool isPositiveResult;
}
