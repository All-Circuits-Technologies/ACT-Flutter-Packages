// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

enum StorageRequestResult {
  /// The request was successful
  success,

  /// The request failed for a permission issue
  accessDenied,

  /// The request failed because of a local io error (file not found, directory not created, etc.)
  ioError,

  /// General failure
  genericError,
}
