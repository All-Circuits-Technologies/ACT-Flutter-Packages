// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// A class representing a storage item.
class StorageFile extends Equatable {
  /// Path of the item
  final String path;

  /// The size of the item
  final int? size;

  /// The last modified date of the item
  final DateTime? lastModified;

  /// The ETag of the item
  final String? eTag;

  /// Class constructor;
  const StorageFile({
    required this.path,
    this.size,
    this.lastModified,
    this.eTag,
  });

  /// Get the properties of the object.
  @override
  List<Object?> get props => [
        path,
        size,
        lastModified,
        eTag,
      ];
}
