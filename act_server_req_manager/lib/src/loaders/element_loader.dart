// SPDX-FileCopyrightText: 2024 Benoit Rolandeau <benoit.rolandeau@allcircuits.com>
//
// SPDX-License-Identifier: LicenseRef-ALLCircuits-ACT-1.1

import 'package:act_server_req_manager/src/loaders/abs_element_loader.dart';

/// This loader loads element from the given [_callback]
class ElementLoader<T> extends AbsElementLoader<T> {
  /// This is the callback to use in order to request the data from provider
  final ElementLoaderCallback<T> _callback;

  /// This is the number of elements really used by the companion
  int elementsSizeReallyUsed;

  /// Class constructor
  ElementLoader({
    required ElementLoaderCallback<T> callback,
  })  : _callback = callback,
        elementsSizeReallyUsed = 0;

  /// Load the elements from provider
  ///
  /// [limit] is the number (max limit) of elements we want to get from provider, we can get less.
  /// [offset] can be used to specify the index of the first element to retrieve from the provider.
  ///
  /// If the method returns null it means that an error occurred.
  /// If the method returns an empty list or a list with a length smaller than the [limit], it means
  /// that all the data have been loaded and no more are available.
  @override
  Future<List<T>?> loadFromProvider({
    required int offset,
    required int limit,
  }) async =>
      _callback(
        offset: offset,
        limit: limit,
      );

  /// {@macro abs_server_item_loader.clearLoadedElements}
  @override
  Future<void> clearLoadedElements() async {
    elementsSizeReallyUsed = 0;
    return super.clearLoadedElements();
  }
}
