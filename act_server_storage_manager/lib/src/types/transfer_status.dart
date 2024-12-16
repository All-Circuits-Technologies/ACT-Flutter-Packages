// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

enum TransferStatus {
  /// The download task is in progress.
  inProgress,

  /// The download task is paused.
  paused,

  /// The download task is canceled.
  canceled,

  /// The download task completed successfully.
  success,

  /// The download task failed.
  failure;

  /// Returns `true` if the transfer is done (success or failure), `false` otherwise.
  bool get isCompleted => this == success || this == failure;
}
