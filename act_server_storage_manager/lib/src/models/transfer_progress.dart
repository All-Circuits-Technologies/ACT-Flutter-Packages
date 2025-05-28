// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_storage_manager/src/types/transfer_status.dart';
import 'package:equatable/equatable.dart';

/// Class representing the transfer progress of a file being downloaded or uploaded
class TransferProgress extends Equatable {
  /// The total bytes to transfer
  ///
  /// Negative when unknown.
  final int totalBytes;

  /// The bytes transferred
  final int bytesTransferred;

  /// The transfer status
  final TransferStatus transferStatus;

  /// Get the transfer progress in percentage
  double get progress => totalBytes <= 0 ? 0 : bytesTransferred / totalBytes;

  /// Constructor
  const TransferProgress({
    required this.totalBytes,
    required this.bytesTransferred,
    required this.transferStatus,
  });

  /// Get the properties of the object
  @override
  List<Object?> get props => [
        totalBytes,
        bytesTransferred,
        transferStatus,
      ];
}
