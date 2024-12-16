// SPDX-FileCopyrightText: 2023 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// The policy to apply when we fail to log in
enum LoginFailPolicy {
  errorIfLoginFails,
  retryOnceIfLoginFails,
}
