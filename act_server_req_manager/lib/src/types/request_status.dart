// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The result of the request
enum RequestStatus {
  /// The request succeeded
  success(isOk: true),

  /// The request fails with a login error
  loginError,

  /// The request fails with a global error
  globalError;

  /// Returns true if the request result is equal to [success]
  final bool isOk;

  /// Class constructor
  const RequestStatus({this.isOk = false});
}
