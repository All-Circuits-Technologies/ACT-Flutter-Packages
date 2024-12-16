// SPDX-FileCopyrightText: 2024 Anthony Loiseau <anthony.loiseau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

enum AuthDeleteStatus {
  /// Account is deleted
  done(isSuccess: true),

  /// Deletion failed due to a network issue
  networkError,

  /// Deletion failed to to another error
  genericError;

  /// The status represents a success
  final bool isSuccess;

  /// The status represents an error
  bool get isError => !isSuccess;

  /// Class constructor
  const AuthDeleteStatus({
    this.isSuccess = false,
  });
}
