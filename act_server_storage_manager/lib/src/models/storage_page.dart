// SPDX-FileCopyrightText: 2024 Théo Magne <theo.magne@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_storage_manager/src/models/storage_file.dart';
import 'package:equatable/equatable.dart';

/// Class representing a page of items in a storage service. Note that it uses
/// a list of strings therefore it is not really an equatable object since the
/// equality of the items is not checked, only the reference to the list.
class StoragePage extends Equatable {
  /// List of items in the page
  final List<StorageFile> items;

  /// The next page token
  final String? nextPageToken;

  /// True if there is a next page to fetch
  final bool hasNextPage;

  /// Constructor for [StoragePage]
  StoragePage({
    required List<StorageFile> items,
    this.nextPageToken,
    this.hasNextPage = false,
  })  : items = List.from(items),
        super();

  /// This method prepends the previous page items and creates a new object.
  ///
  /// If [previousPage] is null, the method returns this
  StoragePage prependPreviousPage(StoragePage? previousPage) {
    if (previousPage == null) {
      // Nothing to do
      return this;
    }

    final tmpItems = List<StorageFile>.from(previousPage.items)..addAll(items);

    return StoragePage(
      items: tmpItems,
      nextPageToken: nextPageToken,
      hasNextPage: hasNextPage,
    );
  }

  /// Get the properties of the object.
  @override
  List<Object?> get props => [
        items,
        nextPageToken,
        hasNextPage,
      ];
}
