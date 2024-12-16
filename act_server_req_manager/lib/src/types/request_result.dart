// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The result of the request
enum RequestResult {
  success(isOk: true),
  loginError,
  globalError;

  /// Returns true if the request result is equal to [success]
  final bool isOk;

  /// Class constructor
  const RequestResult({this.isOk = false});
}
