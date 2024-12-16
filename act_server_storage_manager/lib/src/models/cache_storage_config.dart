// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:equatable/equatable.dart';

/// Configuration for the cache storage.
class CacheStorageConfig extends Equatable {
  /// Key to identify the cache, required to identify which cache to use.
  final String key;

  /// Duration after which the cached element is considered stale.
  final Duration stalePeriod;

  /// Maximum number of objects to store in the cache.
  final int maxNbOfCachedObjects;

  /// Constructor for [CacheStorageConfig].
  const CacheStorageConfig({
    required this.key,
    required this.stalePeriod,
    required this.maxNbOfCachedObjects,
  });

  /// Get the properties of the object.
  @override
  List<Object> get props => [
        key,
        stalePeriod,
        maxNbOfCachedObjects,
      ];
}
