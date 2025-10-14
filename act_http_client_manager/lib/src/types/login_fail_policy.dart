// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The policy to apply when we fail to log in
enum LoginFailPolicy {
  /// If the login fails we return an error
  errorIfLoginFails,

  /// If the login fails we retry once before returning an error
  retryOnceIfLoginFails,
}
