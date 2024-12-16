// SPDX-FileCopyrightText: 2023 Anthony Loiseau <anthony.loiseau@allcircuits.com>
// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// Represents the errors which may happens with the characteristics
enum CharacteristicsError {
  success(isSuccess: true),
  genericError,
  missAuthorization;

  /// True if the boolean is linked to success state
  final bool isSuccess;

  /// Class constructor
  const CharacteristicsError({this.isSuccess = false});
}
