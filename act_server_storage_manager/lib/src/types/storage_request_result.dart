// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

/// This is the result of storage request
enum StorageRequestResult {
  /// The request was successful
  success,

  /// The request failed for a permission issue
  accessDenied,

  /// The request failed because of a local io error (file not found, directory not created, etc.)
  ioError,

  /// The request failed because it is not supported by underlying service
  unsupportedError,

  /// General failure
  genericError,
}
